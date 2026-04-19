/*
    SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#include "lockmanager.h"

#include <QDebug>

#include "linux/solidlockbackend.h"

LockManager::LockManager(QObject *parent)
    : QObject(parent)
    , m_backend(new SolidLockBackend(this))
    , m_inhibit(false)
{
}

LockManager::~LockManager() = default;

void LockManager::toggleInhibitScreenLock(const QString &explanation)
{
    if (!m_backend)
        return;

    if (m_inhibit) {
        m_backend->setInhibitionOff();
    } else {
        m_backend->setInhibitionOn(explanation);
    }
    m_inhibit = !m_inhibit;
}

void LockManager::setInhibitionOff()
{
    if (!m_backend)
        return;
    m_backend->setInhibitionOff();

    m_inhibit = false;
}

void LockManager::setInhibitionOn(const QString &explanation)
{
    if (!m_backend)
        return;

    m_backend->setInhibitionOn(explanation);

    m_inhibit = true;
}
