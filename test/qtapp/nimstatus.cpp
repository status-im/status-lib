#include "nimstatus.hpp"

NimStatus::NimStatus(const QString& fleet){
    _ptr = newStatusInstance(fleet.toLocal8Bit().data());
}

NimStatus::~NimStatus(){
    freeStatusInstance(_ptr);
    _ptr = nullptr;
}

void NimStatus::initializeNode(const QString& statusGoDir, const QString& keystoreDir){
  initNode(_ptr, statusGoDir.toLocal8Bit().data(), keystoreDir.toLocal8Bit().data());
}
