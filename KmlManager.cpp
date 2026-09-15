#include "KmlManager.h"

#include <QFile>
#include <QFileInfo>
#include <QUrl>
#include <QXmlStreamReader>
#include <QXmlStreamWriter>

namespace {
QString localPath(const QString &fileName)
{
    const QUrl url(fileName);
    return url.isLocalFile() ? url.toLocalFile() : fileName;
}
}

KmlManager::KmlManager(QObject *parent)
    : QObject(parent)
{
}

QVariantList KmlManager::places() const
{
    return m_places;
}

QString KmlManager::lastError() const
{
    return m_lastError;
}

void KmlManager::setError(const QString &message)
{
    if (m_lastError == message)
        return;
    m_lastError = message;
    emit lastErrorChanged();
}

bool KmlManager::loadKml(const QString &fileName)
{
    QFile file(localPath(fileName));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        setError(tr("Could not open %1").arg(QFileInfo(file).fileName()));
        return false;
    }

    QXmlStreamReader xml(&file);
    QVariantList loadedPlaces;
    QString currentName;
    QString currentCoordinates;
    bool inPlacemark = false;

    while (!xml.atEnd()) {
        xml.readNext();
        if (xml.isStartElement()) {
            if (xml.name() == u"Placemark") {
                inPlacemark = true;
                currentName.clear();
                currentCoordinates.clear();
            } else if (inPlacemark && xml.name() == u"name") {
                currentName = xml.readElementText(QXmlStreamReader::SkipChildElements);
            } else if (inPlacemark && xml.name() == u"coordinates") {
                currentCoordinates = xml.readElementText(QXmlStreamReader::SkipChildElements).trimmed();
            }
        } else if (xml.isEndElement() && xml.name() == u"Placemark" && inPlacemark) {
            const QStringList values = currentCoordinates.split(u',');
            if (values.size() >= 2) {
                bool longitudeOk = false;
                bool latitudeOk = false;
                const double longitude = values.at(0).toDouble(&longitudeOk);
                const double latitude = values.at(1).toDouble(&latitudeOk);
                if (longitudeOk && latitudeOk) {
                    QVariantMap place;
                    place.insert(QStringLiteral("name"), currentName.isEmpty() ? tr("Untitled place") : currentName);
                    place.insert(QStringLiteral("latitude"), latitude);
                    place.insert(QStringLiteral("longitude"), longitude);
                    loadedPlaces.append(place);
                }
            }
            inPlacemark = false;
        }
    }

    if (xml.hasError()) {
        setError(xml.errorString());
        return false;
    }

    m_places = loadedPlaces;
    setError(QString());
    emit placesChanged();
    return true;
}

bool KmlManager::saveKml(const QString &fileName)
{
    QFile file(localPath(fileName));
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        setError(tr("Could not save %1").arg(QFileInfo(file).fileName()));
        return false;
    }

    QXmlStreamWriter xml(&file);
    xml.setAutoFormatting(true);
    xml.writeStartDocument();
    xml.writeStartElement(QStringLiteral("kml"));
    xml.writeAttribute(QStringLiteral("xmlns"), QStringLiteral("http://www.opengis.net/kml/2.2"));
    xml.writeStartElement(QStringLiteral("Document"));
    xml.writeTextElement(QStringLiteral("name"), QFileInfo(file).completeBaseName());

    for (const QVariant &placeVariant : m_places) {
        const QVariantMap place = placeVariant.toMap();
        xml.writeStartElement(QStringLiteral("Placemark"));
        xml.writeTextElement(QStringLiteral("name"), place.value(QStringLiteral("name")).toString());
        xml.writeStartElement(QStringLiteral("Point"));
        xml.writeTextElement(QStringLiteral("coordinates"), QStringLiteral("%1,%2,0")
                                       .arg(place.value(QStringLiteral("longitude")).toDouble(), 0, 'f', 8)
                                       .arg(place.value(QStringLiteral("latitude")).toDouble(), 0, 'f', 8));
        xml.writeEndElement();
        xml.writeEndElement();
    }

    xml.writeEndElement();
    xml.writeEndElement();
    xml.writeEndDocument();
    setError(QString());
    return true;
}

void KmlManager::addPlace(const QString &name, double latitude, double longitude)
{
    QVariantMap place;
    place.insert(QStringLiteral("name"), name.isEmpty() ? tr("Untitled place") : name);
    place.insert(QStringLiteral("latitude"), latitude);
    place.insert(QStringLiteral("longitude"), longitude);
    m_places.append(place);
    emit placesChanged();
}

void KmlManager::clear()
{
    if (m_places.isEmpty())
        return;
    m_places.clear();
    emit placesChanged();
}