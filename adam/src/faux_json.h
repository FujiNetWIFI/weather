#ifndef FAUX_JSON_H
#define FAUX_JSON_H

extern unsigned char json[6144], json_part[6144];

void faux_parse_json(char * keyword, unsigned char which);

#endif //FAUX_JSON_H
