/*
 * SPDX-FileCopyrightText: 2020 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef TRACKSMODEL_H
#define TRACKSMODEL_H

#include <QAbstractListModel>
#include <QObject>

class Track;

class TracksModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
public:
    explicit TracksModel(QObject *parent = nullptr);
    enum {
        TextRole = Qt::UserRole,
        LanguageRole,
        TitleRole,
        IDRole,
        CodecRole
    };
    int count() const;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    virtual QHash<int, QByteArray> roleNames() const override;

public Q_SLOTS:
    void setTracks(QMap<int, Track *> tracks);

Q_SIGNALS:
    void countChanged();

private:
    QMap<int, Track *> m_tracks;
};

#endif // TRACKSMODEL_H
