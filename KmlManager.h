#pragma once

#include <QObject>
#include <QVariantList>

class KmlManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList places READ places NOTIFY placesChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    explicit KmlManager(QObject *parent = nullptr);

    QVariantList places() const;
    QString lastError() const;

    Q_INVOKABLE bool loadKml(const QString &fileName);
    Q_INVOKABLE bool saveKml(const QString &fileName);
    Q_INVOKABLE void addPlace(const QString &name, double latitude, double longitude);
    Q_INVOKABLE void clear();

signals:
    void placesChanged();
    void lastErrorChanged();

private:
    void setError(const QString &message);

    QVariantList m_places;
    QString m_lastError;
};