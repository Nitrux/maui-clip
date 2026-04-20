#include <QCommandLineParser>

#include <QDirIterator>
#include <QQmlContext>
#include <QFileInfo>
#include <QIcon>

#include <QQmlApplicationEngine>

#include <KLocalizedString>
#include "controllers/lockmanager.h"

#include <MauiKit4/Core/mauiapp.h>
#include <MauiKit4/FileBrowsing/fmstatic.h>
#include <MauiKit4/FileBrowsing/moduleinfo.h>

#ifdef CLIP_BUILD_BUNDLED_PREVIEW_PROVIDER
#include <taglib/taglib.h>
#include <libavutil/avutil.h>
#endif

#ifdef MPV_AVAILABLE
#include "backends/mpv/mpvobject.h"
#endif

#include "models/videosmodel.h"
#include "models/tagsmodel.h"
#ifdef CLIP_BUILD_BUNDLED_PREVIEW_PROVIDER
#include "utils/thumbnailer.h"
#endif

#include "utils/clip.h"
#include "../clip_version.h"

#include <QApplication>
#include <QSurfaceFormat>

#define CLIP_URI "org.maui.clip"

static const  QList<QUrl> getFolderVideos(const QString &path)
{
    QList<QUrl> urls;

    if (QFileInfo(path).isDir())
    {
        QDirIterator it(path, FMStatic::FILTER_LIST[FMStatic::FILTER_TYPE::IMAGE], QDir::Files, QDirIterator::Subdirectories);
        while (it.hasNext())
            urls << QUrl::fromLocalFile(it.next());

    }else if (QFileInfo(path).isFile())
        urls << path;

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

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QSurfaceFormat format;
    format.setAlphaBufferSize(8);
    QSurfaceFormat::setDefaultFormat(format);
    QApplication app(argc, argv);

#ifdef MPV_AVAILABLE
    // Qt sets the locale in the QGuiApplication constructor, but libmpv
    // requires the LC_NUMERIC category to be set to "C", so change it back.
    std::setlocale(LC_NUMERIC, "C");
#endif

    app.setOrganizationName(QStringLiteral("Maui"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("clip"), QIcon(QStringLiteral(":/img/assets/clip.svg"))));
    QGuiApplication::setDesktopFileName(QStringLiteral("org.maui.clip"));

    KLocalizedString::setApplicationDomain("clip");
    KAboutData about(QStringLiteral("clip"),
                     QStringLiteral("Clip"),
                     CLIP_VERSION_STRING,
                     i18n("Browse and play your videos."),
                     KAboutLicense::LGPL_V3,
                     APP_COPYRIGHT_NOTICE,
                     QString(GIT_BRANCH) + "/" + QString(GIT_COMMIT_HASH));

    about.addAuthor(QStringLiteral("Camilo Higuita"), i18n("Developer"), QStringLiteral("milo.h@aol.com"));
    about.setHomepage("https://mauikit.org");
    about.setProductName("maui/clip");
    about.setBugAddress("https://invent.kde.org/maui/clip/-/issues");
    about.setOrganizationDomain(CLIP_URI);
    about.setDesktopFileName("org.maui.clip");
    about.setProgramLogo(app.windowIcon());

    const auto FBData = MauiKitFileBrowsing::aboutData();
    about.addComponent(FBData.name(), MauiKitFileBrowsing::buildVersion(), FBData.version(), FBData.webAddress());

//    about.addComponent("FFmpeg", "", QString::fromLatin1(av_version_info()), QString::fromLatin1(avutil_license()));

#ifdef MPV_AVAILABLE
    about.addComponent("MPV");
#endif

#ifdef CLIP_BUILD_BUNDLED_PREVIEW_PROVIDER
    about.addComponent("TagLib",
                       "",
                       QString("%1.%2.%3").arg(QString::number(TAGLIB_MAJOR_VERSION),QString::number(TAGLIB_MINOR_VERSION),QString::number(TAGLIB_PATCH_VERSION)),
                       "https://taglib.org/api/index.html");
#endif

    KAboutData::setApplicationData(about);
    MauiApp::instance()->setIconName(QStringLiteral("clip"));

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

#ifdef MPV_AVAILABLE
    qRegisterMetaType<TracksModel*>();
    qmlRegisterType<MpvObject>("mpv", 1, 0, "MpvObject");
    qmlRegisterType(QUrl("qrc:/app/maui/clip/views/player/MPVPlayer.qml"), CLIP_URI, 1, 0, "Video");
#else
    qmlRegisterType(QUrl("qrc:/app/maui/clip/views/player/Player.qml"), CLIP_URI, 1, 0, "Video");
#endif

    qmlRegisterSingletonType<LockManager>(CLIP_URI, 1, 0, "LockManager", [](QQmlEngine*, QJSEngine*) -> QObject* {
        return new LockManager;
    });

    engine.load(url);

    return app.exec();
}
