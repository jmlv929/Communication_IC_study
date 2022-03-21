/*************************************
*功能: 咬尾卷积码的译码  *
 *************************************/

#include <string.h>

#define STATENUM	64
#define CODERATE	3
#define MAXINFOLEN	200
#define MINVALUE	-1000000

typedef struct StateInfo {
  Uint8 next_state0;	//输入比特0时，编码器下一时刻的状态
  Uint8 next_state1;	//输入比特1时，编码器下一时刻的状态
  Uint8 state_out0;	//输入比特0时，编码器的输出
  Uint8 state_out1;	//输入比特1时，编码器的输出
} StateInfoType;

StateInfoType gStateInfoTable[STATENUM] = {
  { 0,  32, 0, 7 }, { 0,  32, 7, 0 }, { 1,  33, 1, 6 }, { 1,  33, 6, 1 },
  { 2,  34, 4, 3 }, { 2,  34, 3, 4 }, { 3,  35, 5, 2 }, { 3,  35, 2, 5 },
  { 4,  36, 3, 4 }, { 4,  36, 4, 3 }, { 5,  37, 2, 5 }, { 5,  37, 5, 2 },
  { 6,  38, 7, 0 }, { 6,  38, 0, 7 }, { 7,  39, 6, 1 }, { 7,  39, 1, 6 },
  { 8,  40, 7, 0 }, { 8,  40, 0, 7 }, { 9,  41, 6, 1 }, { 9,  41, 1, 6 },
  {10,  42, 3, 4 }, {10,  42, 4, 3 }, {11,  43, 2, 5 }, {11,  43, 5, 2 },
  {12,  44, 4, 3 }, {12,  44, 3, 4 }, {13,  45, 5, 2 }, {13,  45, 2, 5 },
  {14,  46, 0, 7 }, {14,  46, 7, 0 }, {15,  47, 1, 6 }, {15,  47, 6, 1 },
  {16,  48, 6, 1 }, {16,  48, 1, 6 }, {17,  49, 7, 0 }, {17,  49, 0, 7 },
  {18,  50, 2, 5 }, {18,  50, 5, 2 }, {19,  51, 3, 4 }, {19,  51, 4, 3 },
  {20,  52, 5, 2 }, {20,  52, 2, 5 }, {21,  53, 4, 3 }, {21,  53, 3, 4 },
  {22,  54, 1, 6 }, {22,  54, 6, 1 }, {23,  55, 0, 7 }, {23,  55, 7, 0 },
  {24,  56, 1, 6 }, {24,  56, 6, 1 }, {25,  57, 0, 7 }, {25,  57, 7, 0 },
  {26,  58, 5, 2 }, {26,  58, 2, 5 }, {27,  59, 4, 3 }, {27,  59, 3, 4 },
  {28,  60, 2, 5 }, {28,  60, 5, 2 }, {29,  61, 3, 4 }, {29,  61, 4, 3 },
  {30,  62, 6, 1 }, {30,  62, 1, 6 }, {31,  63, 7, 0 }, {31,  63, 0, 7 } };

void conv_decode_tibi(
  Uint32 info_len,
  Sint8 *input_ptr,
  Uint8 *output_ptr
) {
  Sint32 i, j, k, l;
  Sint32 gamma;
  Sint32 metric_max;

  Uint8  tmp_out0;
  Uint8  half_state_num;
  Uint8  current_state, last_state;
  Sint32 metric[STATENUM*2];
  Uint8  path[STATENUM*MAXINFOLEN];

  half_state_num = STATENUM / 2;

  memset((void *)metric, MINVALUE, sizeof(Sint32)*STATENUM*2);

  for (k = 0; k < info_len; k++) {
    for (j = 0; j < STATENUM; ) {
      i = (j+1) / 2;
      tmp_out0 = gStateInfoTable[j].state_out0;
      gamma = 0;
      for (l = 0; l < CODERATE; l++) {
        gamma += (1 - 2*((tmp_out0 >> l) & 0x01))*input_ptr[l+k*CODERATE]; }

      if ((metric[j]+gamma) > (metric[j+1] - gamma)) {
        metric[i+STATENUM] = metric[j]+gamma;
        path[i+k*STATENUM] = j; }
      else {
        metric[i+STATENUM] = metric[j+1] - gamma;
        path[i+k*STATENUM] = j+1; }

      i += half_state_num;
      if ((metric[j] - gamma) > (metric[j+1]+gamma)) {
        metric[i+STATENUM] = metric[j] - gamma;
        path[i+k*STATENUM] = j; }
      else {
        metric[i+STATENUM] = metric[j+1]+gamma;
        path[i+k*STATENUM] = j+1; }

      j += 2; }

    memcpy((void *)metric, (void *)(metric+STATENUM), sizeof(Sint32)*STATENUM);
    memset((void *)(metric+STATENUM), MINVALUE, sizeof(Sint32)*STATENUM); }

  metric_max = metric[0];
  current_state = 0;
  for (i = 1; i < STATENUM; i++) {
    if (metric[i] > metric_max) {
      metric_max = metric[i];
      current_state = i; } }

  for (k = info_len - 1; k > -1; k--) {
    if (current_state < half_state_num) {
      output_ptr[k] = 0;
      last_state = path[current_state+k*STATENUM]; }
    else {
      output_ptr[k] = 1;
      last_state = path[current_state+k*STATENUM]; }
    current_state = last_state; } }
