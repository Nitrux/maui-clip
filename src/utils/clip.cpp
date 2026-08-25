#include "clip.h"

#include <QDesktopServices>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QSettings>
#include <QUrl>

#include <MauiKit4/FileBrowsing/fmstatic.h>

namespace
{
QString sanitizeSourcePath(const QString &path)
{
    const auto trimmedPath = path.trimmed();

    if (trimmedPath.isEmpty()) {
        return {};
    }

    QUrl url(trimmedPath);

    if (url.scheme().isEmpty()) {
        url = QUrl::fromLocalFile(QDir::cleanPath(trimmedPath));
    } else if (url.isLocalFile()) {
        url = QUrl::fromLocalFile(QDir::cleanPath(url.toLocalFile()));
    }

    if (!url.isValid() || !url.isLocalFile() || !FMStatic::fileExists(url) || !FMStatic::isDir(url)) {
        return {};
    }

    return url.toString();
}

QStringList sanitizeSourcePaths(const QStringList &paths)
{
    QStringList sources;

    for (const auto &path : paths) {
        const auto sanitizedPath = sanitizeSourcePath(path);

        if (!sanitizedPath.isEmpty() && !sources.contains(sanitizedPath)) {
            sources << sanitizedPath;
        }
    }

    return sources;
}

QStringList sourcePreviews(const QUrl &sourceUrl)
{
    QStringList previews;

    if (!sourceUrl.isLocalFile()) {
        return previews;
    }

    QDirIterator it(sourceUrl.toLocalFile(),
                    QStringList() << FMStatic::FILTER_LIST[FMStatic::FILTER_TYPE::VIDEO],
                    QDir::Files,
                    QDirIterator::Subdirectories);

    while (it.hasNext() && previews.size() < 4) {
        const QUrl fileUrl = QUrl::fromLocalFile(it.next());
#ifdef CLIP_BUILD_BUNDLED_PREVIEW_PROVIDER
        const QString thumbnail = QStringLiteral("image://preview/") + fileUrl.toString();
#else
        const auto info = FMStatic::getFileInfo(fileUrl);
        const auto thumbnailKey = FMH::MODEL_NAME[FMH::MODEL_KEY::THUMBNAIL];
        auto thumbnail = info.value(thumbnailKey).toString();

        if (thumbnail.isEmpty()) {
            thumbnail = "image://thumbnailer/" + fileUrl.toString();
        }
#endif

        if (!thumbnail.isEmpty() && !previews.contains(thumbnail)) {
            previews << thumbnail;
        }
    }

    return previews;
}
}

Clip::Clip(QObject *parent)
    : QObject(parent)
    , m_sourcesWatcher(new QFileSystemWatcher(this))
{
    FMStatic::createDir(FMStatic::PicturesPath, "screenshots");
    connect(m_sourcesWatcher, &QFileSystemWatcher::directoryChanged, this, [this](const QString &)
    {
        Q_EMIT sourceContentsChanged();
    });
    updateSourcesWatcher();
}

const QStringList Clip::getSourcePaths()
{
    const QStringList defaultSources = {FMStatic::VideosPath};

    QSettings settings;
    settings.beginGroup("Settings");

    const auto configuredSources = settings.contains("Sources") ? settings.value("Sources").toStringList() : defaultSources;
    const auto sources = sanitizeSourcePaths(configuredSources);

    if (configuredSources != sources) {
        settings.setValue("Sources", sources);
    }

    settings.endGroup();
    return sources;
}

void Clip::updateSourcesWatcher()
{
    const auto watchedDirectories = m_sourcesWatcher->directories();
    if (!watchedDirectories.isEmpty()) {
        m_sourcesWatcher->removePaths(watchedDirectories);
    }

    QStringList sourceDirectories;
    for (const auto &source : getSourcePaths()) {
        const QUrl url(source);
        if (url.isLocalFile() && QFileInfo(url.toLocalFile()).isDir()) {
            sourceDirectories << url.toLocalFile();
        }
    }

    if (!sourceDirectories.isEmpty()) {
        m_sourcesWatcher->addPaths(sourceDirectories);
    }
}

void Clip::saveSourcePath(const QStringList &paths)
{
    auto sources = getSourcePaths();
    const auto newSources = sanitizeSourcePaths(paths);

    for (const auto &path : newSources) {
        if (!sources.contains(path)) {
            sources << path;
        }
    }

    QSettings settings;
    settings.beginGroup("Settings");
    settings.setValue("Sources", sources);
    settings.endGroup();
}

void Clip::removeSourcePath(const QString &path)
{
    const auto sanitizedPath = sanitizeSourcePath(path);
    auto sources = getSourcePaths();

    if (!sanitizedPath.isEmpty()) {
        sources.removeAll(sanitizedPath);
    }

    QSettings settings;
    settings.beginGroup("Settings");
    settings.setValue("Sources", sources);
    settings.endGroup();
}

QVariantList Clip::sourcesModel() const
{
    QVariantList res;
    const auto sources = getSourcePaths();

    return std::accumulate(sources.constBegin(), sources.constEnd(), res, [](QVariantList &result, const QString &urlString)
    {
        const QUrl url(urlString);
        auto source = FMStatic::getFileInfo(url);

        if (url.isLocalFile()) {
            source[FMH::MODEL_NAME[FMH::MODEL_KEY::PATH]] = QDir::toNativeSeparators(url.toLocalFile());

            if (source[FMH::MODEL_NAME[FMH::MODEL_KEY::LABEL]].toString().isEmpty()) {
                source[FMH::MODEL_NAME[FMH::MODEL_KEY::LABEL]] = QFileInfo(url.toLocalFile()).fileName();
            }
        }

        source[FMH::MODEL_NAME[FMH::MODEL_KEY::PREVIEW]] = sourcePreviews(url).join(",");

        result << source;
        return result;
    });
}

QStringList Clip::sources() const
{
    return getSourcePaths();
}

void Clip::openVideos(const QList<QUrl> &urls)
{
    Q_EMIT this->openUrls(QUrl::toStringList(urls));
}

void Clip::refreshCollection()
{
    const auto sources = getSourcePaths();
    qDebug() << "getting default sources to look up" << sources;
}

bool Clip::removeFiles(const QList<QUrl> &urls)
{
    if (!FMStatic::removeFiles(urls)) {
        return false;
    }

    Q_EMIT filesRemoved(QUrl::toStringList(urls));
    return true;
}

void Clip::showInFolder(const QStringList &urls)
{
    for (const auto &url : urls) {
        QDesktopServices::openUrl(FMStatic::fileDir(url));
    }
}

void Clip::addSources(const QStringList &paths)
{
    saveSourcePath(paths);
    updateSourcesWatcher();
    Q_EMIT sourcesChanged();
}

void Clip::removeSources(const QString &path)
{
    removeSourcePath(path);
    updateSourcesWatcher();
    Q_EMIT sourcesChanged();
}
