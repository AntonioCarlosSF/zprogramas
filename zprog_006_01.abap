REPORT zprog_006_01.
TABLES: zprodutos_01,zestoque_01,zvendas_01.
TYPES: BEGIN OF ty_tudo,
         produto     TYPE zproduto_01,
         descricao   TYPE zdesc_produto_01,
         preco       TYPE zpreco_01,
         quantidade  TYPE zquantidade_01,
         valor_venda TYPE zvenda_01,
         data        TYPE datum,
         hora        TYPE uzeit,
         valor_estoque type p decimals 1,
       END OF ty_tudo.
DATA: lt_tudo TYPE TABLE OF ty_tudo,
      ls_tudo LIKE LINE OF lt_tudo.

SELECT
  zprodutos_01~produto
  zprodutos_01~desc_produto
  zvendas_01~preco
  zvendas_01~quantidade
  zvendas_01~venda
  zvendas_01~data
  zvendas_01~hora
  FROM zprodutos_01
  LEFT JOIN zestoque_01 ON zprodutos_01~produto = zestoque_01~produto
  LEFT join zvendas_01 on zprodutos_01~produto = zvendas_01~produto
  into table lt_tudo.

  LOOP AT lt_tudo INTO ls_tudo.
  READ TABLE lt_tudo INTO ls_tudo WITH KEY produto = ls_tudo-produto.

  IF sy-subrc <> 0.
    ls_tudo-desc_produto = 'Produto não encontrado'.
  ENDIF.


ENDLOOP.