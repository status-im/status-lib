#ifndef __statuslib__
#define __statuslib__

void NimMain(void);

void helloWorld(void);

typedef struct Status Status;

Status* newStatusInstance(char* fleetConfig);

void freeStatusInstance(Status* instance);

void ensureDirectories(char* dataDir, char* tmpDir, char* logDir);

void initNode(Status* self, char* statusGoDir, char* keystoreDir);

#endif /* __statuslib__ */
