#include <QCommandLineParser>

#include <QDirIterator>
#include <QQmlContext>
#include <QFileInfo>
#include <QIcon>
#include <QDate>

#include <QQmlApplicationEngine>

#include <KLocalizedString>

#include <MauiKit4/Core/mauiapp.h>
#include <MauiKit4/FileBrowsing/fmstatic.h>
#include <MauiKit4/FileBrowsing/moduleinfo.h>

#ifdef CLIP_BUILD_BUNDLED_PREVIEW_PROVIDER
#include <taglib/taglib.h>
#include <libavutil/avutil.h>
#endif

#include "backends/mpv/mpvobject.h"

#include "models/videosmodel.h"
#include "models/tagsmodel.h"
#ifdef CLIP_BUILD_BUNDLED_PREVIEW_PROVIDER
#include "utils/thumbnailer.h"
#endif

#include "utils/clip.h"
#include "../clip_version.h"

#include <QGuiApplication>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QSurfaceFormat>

#define CLIP_URI "org.maui.clip"

static const  QList<QUrl> getFolderVideos(const QString &path)
{
    QList<QUrl> urls;

    if (QFileInfo(path).isDir())
    {
        QDirIterator it(path, FMStatic::FILTER_LIST[FMStatic::FILTER_TYPE::VIDEO], QDir::Files, QDirIterator::Subdirectories);
        while (it.hasNext())
            urls << QUrl::fromLocalFile(it.next());

    }else if (QFileInfo(path).isFile())
        urls << QUrl::fromLocalFile(path);

    return urls;
}

static const QList<QUrl> openFiles(const QStringList &files)
{
    QList<QUrl>  urls;

    if(files.size()>1)
    {
        for(const auto &file : files)
            urls << QUrl::fromUserInput(file);
    }
    else if(files.size() == 1)
    {
        auto folder = QFileInfo(files.first()).dir().absolutePath();
        urls = getFolderVideos(folder);
        urls.removeOne(QUrl::fromLocalFile(files.first()));
        urls.insert(0,QUrl::fromLocalFile(files.first()));
    }

    return urls;
}

static QString graphicsApiName(QSGRendererInterface::GraphicsApi api)
{
    if (api == QSGRendererInterface::OpenGL) {
        return QStringLiteral("OpenGL");
    }

    return QStringLiteral("GraphicsApi(%1)").arg(static_cast<int>(api));
}

static void configureGraphicsApiForMpv()
{
    const auto graphicsApi = QQuickWindow::graphicsApi();
    if (graphicsApi != QSGRendererInterface::Unknown
        && graphicsApi != QSGRendererInterface::OpenGL) {
        qInfo() << "Forcing the scene graph to use OpenGL for Clip's mpv backend instead of"
                << graphicsApiName(graphicsApi);
    }

    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);
}

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    configureGraphicsApiForMpv();

    QSurfaceFormat format;
    format.setAlphaBufferSize(8);
    QSurfaceFormat::setDefaultFormat(format);
    QGuiApplication app(argc, argv);

    // Qt sets the locale in the QGuiApplication constructor, but libmpv
    // requires the LC_NUMERIC category to be set to "C", so change it back.
    std::setlocale(LC_NUMERIC, "C");

    app.setOrganizationName(QStringLiteral("Maui"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("maui-clip"), QIcon(QStringLiteral(":/img/assets/maui-clip.svg"))));
    QGuiApplication::setDesktopFileName(QStringLiteral("org.maui.clip"));

    KLocalizedString::setApplicationDomain("clip");
    KAboutData about(QStringLiteral("clip"),
                     i18n("Clip"),
                     CLIP_VERSION_STRING,
                     i18n("Browse and play your videos."),
                     KAboutLicense::LGPL_V3,
                     i18n("© %1 Made by Nitrux | Built with MauiKit", QString::number(QDate::currentDate().year())),
                     QString(GIT_BRANCH) + "/" + QString(GIT_COMMIT_HASH));

    about.addAuthor(QStringLiteral("Camilo Higuita"), i18n("Developer"), QStringLiteral("milo.h@aol.com"));
    about.addAuthor(QStringLiteral("Uri Herrera"), i18n("Developer"), QStringLiteral("uri_herrera@nxos.org"));
    about.setHomepage("https://nxos.org");
    about.setProductName("nitrux/clip");
    about.setOrganizationDomain(CLIP_URI);
    about.setDesktopFileName("org.maui.clip");
    about.setProgramLogo(app.windowIcon());

    const auto FBData = MauiKitFileBrowsing::aboutData();
    about.addComponent(FBData.name(), MauiKitFileBrowsing::buildVersion(), FBData.version(), FBData.webAddress());

//    about.addComponent("FFmpeg", "", QString::fromLatin1(av_version_info()), QString::fromLatin1(avutil_license()));

#ifdef CLIP_BUILD_BUNDLED_PREVIEW_PROVIDER
    about.addComponent("TagLib",
                       "",
                       QString("%1.%2.%3").arg(QString::number(TAGLIB_MAJOR_VERSION),QString::number(TAGLIB_MINOR_VERSION),QString::number(TAGLIB_PATCH_VERSION)),
                       "https://taglib.org/api/index.html");
#endif

    KAboutData::setApplicationData(about);
    MauiApp::instance()->setIconName(QStringLiteral("qrc:/img/assets/maui-clip.svg"));

    QCommandLineParser parser;

    about.setupCommandLine(&parser);
    parser.process(app);

    about.processCommandLine(&parser);

    const QStringList args = parser.positionalArguments();

    QPair<QString, QList<QUrl>> arguments;
    arguments.first = "collection";

    if(!args.isEmpty())
    {
        arguments.first = "viewer";
        arguments.second = openFiles(args);
    }

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/app/maui/clip/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url, &arguments](QObject *obj, const QUrl &objUrl)
    {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);

        if(!arguments.second.isEmpty())
            Clip::instance ()->openVideos(arguments.second);

    }, Qt::QueuedConnection);

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));

    engine.rootContext()->setContextProperty("initModule", arguments.first);
    engine.rootContext()->setContextProperty("initData", QUrl::toStringList(arguments.second));

    qmlRegisterType<VideosModel>(CLIP_URI, 1, 0, "Videos");
    qmlRegisterType<TagsModel>(CLIP_URI, 1, 0, "Tags");
    qmlRegisterSingletonInstance<Clip>(CLIP_URI, 1, 0, "Clip", Clip::instance ());
#ifdef CLIP_BUILD_BUNDLED_PREVIEW_PROVIDER
    engine.addImageProvider("preview", new Thumbnailer());
#endif

    qRegisterMetaType<TracksModel*>();
    qmlRegisterType<MpvObject>("mpv", 1, 0, "MpvObject");
    qmlRegisterType(QUrl("qrc:/app/maui/clip/views/player/MPVPlayer.qml"), CLIP_URI, 1, 0, "Video");

    engine.load(url);

    return app.exec();
}
