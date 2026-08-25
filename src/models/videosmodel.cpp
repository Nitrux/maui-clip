#include "videosmodel.h"
#include <QDir>
#include <QFile>
#include <QFileSystemWatcher>
#include <QFileInfo>
#include <QDebug>
#include <QSaveFile>
#include <QTextStream>
#include <MauiKit4/FileBrowsing/tagging.h>
#include <MauiKit4/FileBrowsing/fmstatic.h>
#include <MauiKit4/FileBrowsing/fileloader.h>

static FMH::MODEL videoData(const QUrl &url)
{
    FMH::MODEL model;

    if(!FMStatic::VIDEO_MIMETYPES.contains(FMStatic::getMime(url)))
    {
        return model;
    }

    model= FMStatic::getFileInfoModel(url);

#ifdef CLIP_BUILD_BUNDLED_PREVIEW_PROVIDER
    model.insert(FMH::MODEL_KEY::PREVIEW, "image://preview/" + url.toString());
#else
    model.insert(FMH::MODEL_KEY::PREVIEW, model[FMH::MODEL_KEY::THUMBNAIL]);
#endif
    return model;
}

VideosModel::VideosModel(QObject *parent) : MauiList(parent)
  , m_fileLoader(new FMH::FileLoader(this))
  , m_watcher(new QFileSystemWatcher(this))
  , m_urls(QStringList())
  , m_autoReload(true)
  , m_autoScan(true)
  , m_recursive(true)
{
    qDebug()<< "CREATING GALLERY LIST";

    m_fileLoader->informer = &videoData;
    connect(Clip::instance(), &Clip::filesRemoved, this, &VideosModel::removeUrls);

}

const FMH::MODEL_LIST &VideosModel::items() const
{
    return this->list;
}

void VideosModel::setUrls(const QStringList &urls)
{
    qDebug()<< "setting urls"<< this->m_urls << urls;

    if(this->m_urls == urls)
        return;

    this->m_urls = urls;
    this->clear();
    Q_EMIT this->urlsChanged();
}

QStringList VideosModel::urls() const
{
    return m_urls;
}

void VideosModel::resetUrls()
{
    setUrls({"collection:///"});
}

void VideosModel::setAutoScan(const bool &value)
{
    if(m_autoScan == value)
        return;

    m_autoScan = value;
    Q_EMIT autoScanChanged();
}

bool VideosModel::autoScan() const
{
    return m_autoScan;
}

void VideosModel::setAutoReload(const bool &value)
{
    if(m_autoReload == value)
        return;

    m_autoReload = value;
    Q_EMIT autoReloadChanged();
}

bool VideosModel::autoReload() const
{
    return m_autoReload;
}

QList<QUrl> VideosModel::folders() const
{
    return m_folders;
}

bool VideosModel::recursive() const
{
    return m_recursive;
}

int VideosModel::limit() const
{
    return m_limit;
}

QStringList VideosModel::files() const
{
    return FMH::modelToList(this->list, FMH::MODEL_KEY::URL);
}

void VideosModel::scan(const QStringList &urls, const bool &recursive, const int &limit)
{
    Q_UNUSED(limit)
    this->clear();
    const auto paths = urls.count() == 1 && urls.first() == "collection:///" ? Clip::instance()->sources() : urls;
    const auto pathUrls = QUrl::fromStringList(paths);

    for (const auto &path : pathUrls) {
        this->insertFolder(path);
    }

    m_fileLoader->requestPath(pathUrls, recursive, FMStatic::FILTER_LIST[FMStatic::FILTER_TYPE::VIDEO]);
}

void VideosModel::insertFolder(const QUrl &path)
{
    if (!path.isLocalFile() || !FMStatic::isDir(path) || m_folders.contains(path)) {
        return;
    }

    m_folders << path;

    if (m_autoReload) {
        this->m_watcher->addPath(path.toLocalFile());
    }

    Q_EMIT foldersChanged();
}

bool VideosModel::remove(const int &index)
{
    if (index >= this->list.size() || index < 0)
        return false;

    Q_EMIT this->preItemRemoved(index);
    this->list.removeAt(index);
    Q_EMIT this->postItemRemoved();
    Q_EMIT this->countChanged();

    return true;
}

bool VideosModel::removeUrls(const QStringList &urls)
{
    bool removed = false;

    for (const auto &url : urls)
    {
        const QUrl targetUrl = QUrl::fromUserInput(url);

        for (int i = this->list.size() - 1; i >= 0; --i)
        {
            const auto itemUrl = this->list.at(i).value(FMH::MODEL_KEY::URL);
            const QUrl itemQUrl = QUrl::fromUserInput(itemUrl);

            if (itemUrl == url || (targetUrl.isValid() && itemQUrl.isValid() && targetUrl == itemQUrl))
            {
                removed = this->remove(i) || removed;
            }
        }
    }

    return removed;
}

bool VideosModel::deleteAt(const int &index)
{
    if(index >= this->list.size() || index < 0)
        return false;

    Q_EMIT this->preItemRemoved(index);
    auto item = this->list.takeAt(index);
    Clip::instance()->removeFiles({item[FMH::MODEL_KEY::URL]});
    Q_EMIT this->postItemRemoved();
    Q_EMIT this->countChanged();

    return true;
}

void VideosModel::append(const QVariantMap &item)
{
    Q_EMIT this->preItemAppended();
    this->list << FMH::toModel (item);
    Q_EMIT this->postItemAppended();
    Q_EMIT this->countChanged();
}

void VideosModel::appendUrl(const QString &url)
{
    Q_EMIT this->preItemAppended();
    this->list << FMStatic::getFileInfoModel(QUrl::fromUserInput (url));
    Q_EMIT this->postItemAppended();
    Q_EMIT this->countChanged();
}

bool VideosModel::exportM3U(const QString &filePath)
{
    if (filePath.trimmed().isEmpty() || this->list.isEmpty()) {
        return false;
    }

    const auto targetUrl = QUrl::fromUserInput(filePath);
    const auto localPath = targetUrl.isLocalFile() ? targetUrl.toLocalFile() : filePath;

    QSaveFile file(localPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qWarning() << "Could not open playlist file for writing:" << localPath;
        return false;
    }

    QTextStream out(&file);
    out << "#EXTM3U\n";

    for (const auto &item : this->list) {
        const auto rawUrl = item.value(FMH::MODEL_KEY::URL);
        const auto url = QUrl::fromUserInput(rawUrl);
        out << (url.isValid() ? url.toString() : rawUrl) << "\n";
    }

    if (!file.commit()) {
        qWarning() << "Could not finalize playlist file:" << localPath;
        return false;
    }

    return true;
}

bool VideosModel::importM3U(const QString &filePath)
{
    if (filePath.trimmed().isEmpty()) {
        return false;
    }

    const auto sourceUrl = QUrl::fromUserInput(filePath);
    const auto localPath = sourceUrl.isLocalFile() ? sourceUrl.toLocalFile() : filePath;

    QFile file(localPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Could not open playlist file for reading:" << localPath;
        return false;
    }

    const auto baseDir = QFileInfo(localPath).absolutePath();
    QStringList trackUrls;

    QTextStream in(&file);
    while (!in.atEnd()) {
        const auto line = in.readLine().trimmed();
        if (line.isEmpty() || line.startsWith(QLatin1Char(35))) {
            continue;
        }

        QUrl trackUrl;
        if (line.contains(QStringLiteral("://")) || line.startsWith(QStringLiteral("file:/"))) {
            trackUrl = QUrl::fromUserInput(line);
        } else {
            const QFileInfo lineInfo(line);
            const auto resolvedPath = lineInfo.isAbsolute() ? line : QDir(baseDir).filePath(line);
            trackUrl = QUrl::fromLocalFile(QFileInfo(resolvedPath).absoluteFilePath());
        }

        if (trackUrl.isValid() && !videoData(trackUrl).isEmpty()) {
            trackUrls << trackUrl.toString();
        }
    }

    if (trackUrls.isEmpty()) {
        return false;
    }

    this->clear();
    for (const auto &trackUrl : trackUrls) {
        this->appendUrl(trackUrl);
    }

    return !this->list.isEmpty();
}

void VideosModel::clear()
{
    Q_EMIT this->preListChanged();
    this->list.clear ();
    Q_EMIT this->postListChanged();
    Q_EMIT this->countChanged();

    this->m_watcher->removePaths(m_watcher->directories());

    this->m_folders.clear ();
    Q_EMIT foldersChanged();
}

void VideosModel::rescan()
{
    this->scan(m_urls, m_recursive, m_limit);
}

void VideosModel::setRecursive(bool recursive)
{
    if (m_recursive == recursive)
        return;

    m_recursive = recursive;
    Q_EMIT recursiveChanged(m_recursive);
}

void VideosModel::setlimit(int limit)
{
    if (m_limit == limit)
        return;

    m_limit = limit;
    Q_EMIT limitChanged(m_limit);
}


void VideosModel::classBegin()
{
}

void VideosModel::componentComplete()
{
    connect(m_fileLoader, &FMH::FileLoader::finished,[this](FMH::MODEL_LIST items)
    {
        qDebug() << "Items finished" << items.size();
        Q_EMIT this->filesChanged();
    });

    connect(m_fileLoader, &FMH::FileLoader::itemsReady,[this](FMH::MODEL_LIST items)
    {
        Q_EMIT this->preListChanged();
        this-> list << items;
        Q_EMIT this->postListChanged();
        Q_EMIT this->countChanged();
    });

    connect(m_watcher, &QFileSystemWatcher::directoryChanged, [this](QString dir)
    {
        qDebug()<< "Dir changed" << dir;
        this->rescan();
        //        this->scan({QUrl::fromLocalFile(dir)}, m_recursive);
    });

    connect(m_watcher, &QFileSystemWatcher::fileChanged, [](QString file)
    {
        qDebug()<< "File changed" << file;
    });

    connect(this, &VideosModel::urlsChanged, [this]()
    {
        this->scan(m_urls, m_recursive, m_limit);
    });
     this->scan(m_urls, m_recursive, m_limit);
}
