#include "clip.h"

#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
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
}

Clip::Clip(QObject *parent)
    : QObject(parent)
{
#ifdef MPV_AVAILABLE
    FMStatic::createDir(FMStatic::PicturesPath, "screenshots");
#endif
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

bool Clip::mpvAvailable() const
{
#ifdef MPV_AVAILABLE
    return true;
#else
    return false;
#endif
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

void Clip::showInFolder(const QStringList &urls)
{
    for (const auto &url : urls) {
        QDesktopServices::openUrl(FMStatic::fileDir(url));
    }
}

void Clip::addSources(const QStringList &paths)
{
    saveSourcePath(paths);
    Q_EMIT sourcesChanged();
}

void Clip::removeSources(const QString &path)
{
    removeSourcePath(path);
    Q_EMIT sourcesChanged();
}
