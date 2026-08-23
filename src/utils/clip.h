#pragma once

#include <QDebug>

#include <MauiKit4/Core/fmh.h>
#include <MauiKit4/FileBrowsing/fmstatic.h>

class QFileSystemWatcher;

class Clip : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList sourcesModel READ sourcesModel NOTIFY sourcesChanged FINAL)
    Q_PROPERTY(QStringList sources READ sources NOTIFY sourcesChanged FINAL)

public:
    static Clip * instance()
    {
        static Clip clip;
        return &clip;
    }

    Clip(const Clip &) = delete;
    Clip &operator=(const Clip &) = delete;
    Clip(Clip &&) = delete;
    Clip &operator=(Clip &&) = delete;

public Q_SLOTS:
    QVariantList sourcesModel() const;
    QStringList sources() const;

    void addSources(const QStringList &paths);
    void removeSources(const QString &path);

    void openVideos(const QList<QUrl> &urls);
    void refreshCollection();
    /*File actions*/
    bool removeFiles(const QList<QUrl> &urls);
    static void showInFolder(const QStringList &urls);

private:
    explicit Clip(QObject* parent = nullptr);

    static const QStringList getSourcePaths();

    static void saveSourcePath(QStringList const& paths);

    static void removeSourcePath(const QString &path);

    void updateSourcesWatcher();

Q_SIGNALS:
    void refreshViews(QVariantMap tables);
    void openUrls(QStringList urls);
    void filesRemoved(const QStringList &urls);
    void sourceContentsChanged();
    void sourcesChanged();

private:
    QFileSystemWatcher *m_sourcesWatcher;
};
