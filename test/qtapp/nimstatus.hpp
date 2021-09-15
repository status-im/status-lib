#pragma once

#include <QString>

extern "C"
{
#include "statuslib.h"
}


class NimStatus {
public:
    NimStatus(const QString& fleet);
    virtual ~NimStatus();
    void initializeNode(const QString& statusGoDir, const QString& keystoreDir);
private:
    Status* _ptr;
};
