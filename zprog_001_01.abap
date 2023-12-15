REPORT zprog_001_01.
DATA:lv_int(03) TYPE i, "warning - variáveis do tipo I não tem restrinção de tamanho
     lv_data    TYPE d,
     lv_time    TYPE t,
     lv_char    TYPE c LENGTH 20.

DATA:lv_produto TYPE zproduto_01, "numc
     lv_preco   TYPE zprodutos_01-preco. "curr

lv_int = 10.
lv_data = '20231003'.
lv_time = '155100'.
lv_char = 'ABAP'.

lv_produto = '589'.
lv_preco = '7.89'.

WRITE:lv_int,lv_data,lv_time,lv_char CENTERED.
SKIP.

ULINE.

SKIP.

WRITE:lv_produto,lv_preco.