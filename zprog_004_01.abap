REPORT zprog_004_01.
TABLES zvendas_01.

DATA: ls_venda TYPE zvendas_e_01,
      lt_venda TYPE STANDARD TABLE OF zvendas_e_01.

ls_venda-venda = '1'.
ls_venda-item = '1'.
ls_venda-produto = 'colchão'.
ls_venda-quantidade = '2'.
ls_venda-preco = '9'.
ls_venda-data = '20230809'.
ls_venda-hora = '1324'.

APPEND ls_venda TO lt_venda.
CLEAR ls_venda.

ls_venda-venda = '2'.
ls_venda-item = '3'.
ls_venda-produto = 'travesseiro'.
ls_venda-quantidade = '50'.
ls_venda-preco = '50'.
ls_venda-data = '20230809'.
ls_venda-hora = '1324'.

APPEND ls_venda TO lt_venda.
CLEAR ls_venda.
ls_venda-venda = '4'.
ls_venda-item = '2'.
ls_venda-produto = 'cabide'.
ls_venda-quantidade = '77'.
ls_venda-preco = '90'.
ls_venda-data = '20230809'.
ls_venda-hora = '1324'.

APPEND ls_venda TO lt_venda.

LOOP AT lt_venda INTO ls_venda.
  WRITE: /,'VENDA:',ls_venda-venda,'|','ITEM:',ls_venda-item,'|','PRODUTO:',ls_venda-produto,'|',
        'QUANTIDADE:',ls_venda-quantidade,'|','PREÇO:',ls_venda-preco,'|',
        'DATA:',ls_venda-data,'|','HORA:',ls_venda-hora.
ENDLOOP.