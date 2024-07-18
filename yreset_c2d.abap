*&---------------------------------------------------------------------*
*& Report  YRESET_C2D_2
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT YRESET_C2D_2.

"Tabelas
TABLES: /gfxdsi/cct006.

"Estruturas
TYPES:
BEGIN OF

"Tabelas internas
DATA: lt_cct006 TYPE TABLE OF /gfxdsi/cct006.



SELECTION-SCREEN BEGIN OF BLOCK a1 WITH FRAME TITLE text-001.

          SELECT-OPTIONS: s_empres  for /gfxdsi/cct006-empresa  obligatory,
                          s_filial  for /gfxdsi/cct006-filial obligatory,
                          s_client  for /gfxdsi/cct006-cliente obligatory,
                          s_num_d   for /gfxdsi/cct006-num_documento obligatory,
                          s_item    for /gfxdsi/cct006-item obligatory,
                          s_ano     for /gfxdsi/cct006-ano obligatory.

SELECTION-SCREEN END OF BLOCK a1.


START-OF-SELECTION.

  IF s_empres[] IS INITIAL OR p_filial[] IS INITIAL OR p_client[] IS INITIAL OR p_num_d[] IS INITIAL OR p_item[] IS INITIAL
    OR s_ano[] IS INITIAL.

    MESSAGE 'Todos os parâmetros devem ser preenchidos.' TYPE 'E'.
    RETURN.

  ENDIF.



  SELECT *
    FROM /gfxdsi/cct006
    INTO TABLE @DATA(lt_cct006)
    WHERE empresa IN @p_empres
      AND filial IN @p_filial
      AND cliente IN @p_client
      AND num_documento IN @p_num_d
      AND item IN @p_item
      AND ano IN @p_ano.

  IF sy-subrc IS NOT INITIAL.
    MESSAGE 'Nenhum registro encontrado na tabela CCT006 com os critérios informados.' TYPE 'E'.
    RETURN.
  ENDIF.

  LOOP AT lt_cct006 ASSIGNING FIELD-SYMBOL(<fs_s_cct006>).

    IF <fs_s_cct006>-num_estorno IS NOT INITIAL.
      CALL FUNCTION 'CALL_FBRA'
        EXPORTING
          i_bukrs      = <fs_s_cct006>-empresa
          i_augbl      = <fs_s_cct006>-num_estorno
          i_gjahr      = <fs_s_cct006>-ano_estorno
          i_no_auth    = abap_true
        EXCEPTIONS
          not_possible = 1
          OTHERS       = 2.

      CHECK sy-subrc IS INITIAL.

      CALL FUNCTION 'CALL_FB08'
        EXPORTING
          i_bukrs      = <fs_s_cct006>-empresa
          i_belnr      = <fs_s_cct006>-num_estorno
          i_gjahr      = <fs_s_cct006>-ano_estorno
          i_stgrd      = '01'
          i_update     = 'S'
          i_mode       = 'N'
          i_no_auth    = abap_true
        EXCEPTIONS
          not_possible = 1
          OTHERS       = 2.

    ENDIF.

    IF <fs_s_cct006>-num_compensado IS NOT INITIAL.
      CALL FUNCTION 'CALL_FBRA'
        EXPORTING
          i_bukrs      = <fs_s_cct006>-empresa
          i_augbl      = <fs_s_cct006>-num_compensado
          i_gjahr      = <fs_s_cct006>-ano_compensado
          i_no_auth    = abap_true
        EXCEPTIONS
          not_possible = 1
          OTHERS       = 2.

      CHECK sy-subrc IS INITIAL.

      CALL FUNCTION 'CALL_FB08'
        EXPORTING
          i_bukrs      = <fs_s_cct006>-empresa
          i_belnr      = <fs_s_cct006>-num_compensado
          i_gjahr      = <fs_s_cct006>-ano_compensado
          i_stgrd      = '01'
          i_update     = 'S'
          i_mode       = 'N'
          i_no_auth    = abap_true
        EXCEPTIONS
          not_possible = 1
          OTHERS       = 2.

    ENDIF.

  ENDLOOP.

  WAIT UP TO 2 SECONDS.

  UPDATE /gfxdsi/cct006 SET status         = space,
                            num_compensado = space,
                            ano_compensado = space,
                            num_estorno    = space,
                            ano_estorno    = space
                       WHERE empresa IN @p_empres
                       AND filial IN @p_filial
                       AND cliente IN @p_client
                       AND num_documento IN @p_num_d
                       AND item IN @p_item
                       AND ano IN @p_ano.

    lv_data_v = <fs_s_cct006>-data_venda.
    lv_data_v = lv_data_v - 1.

  UPDATE /gfxdsi/cct006 SET data_venda = l_data_v
                        WHERE empresa IN p_empresa
                         AND filial IN p_filial
                         AND cliente IN p_cliente
                         AND num_documento IN p_num_d
                         AND item IN p_item
                         AND ano IN p_ano.

  DELETE FROM /gfxdsi/cct007 WHERE empresa IN p_empres AND
                                   filial  IN p_filial AND
                                   cliente IN p_client AND
                                   num_parc IN lt_cct006-num_parcela AND
                                   chave_band IN lt_cct006-chave_bandeira. " Specify conditions

  DELETE FROM /gfxdsi/cct008 WHERE empresa IN p_empresa AND
                                   filial    IN  p_filial  AND
                                   num_documento IN lt_cct006 AND
                                   data_venda IN p_data_v AND
                                   item       IN p_item   AND
                                   ano        In p_ano.

  DELETE FROM /gfxdsi/cct009.
