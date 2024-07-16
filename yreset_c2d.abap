REPORT yreset_c2d.

SELECTION-SCREEN BEGIN OF BLOCK a1 WITH FRAME TITLE text-001.
				 PARAMETERS: p_empresa  for tabela obligatory,
							 P_filial   for tabela obligatory,
							 p_cliente  for tabela obligatory,
							 p_num_d    for tabela obligatory,
							 p_item		for tabela obligatory,
							 p_ano 		for tabela obligatory,
							 P_data_v   for tabela obligatory.
					

SELECTION-SCREEN END OF BLOCK a1.

START-OF-SELECTION.

  IF p_empresa IS INITIAL OR p_filial IS INITIAL OR p_cliente IS INITIAL OR p_num_d IS INITIAL OR p_item IS INITIAL 
    OR p_ano IS INITIAL OR p_data_v IS INITIAL.
    
    MESSAGE 'Todos os parâmetros devem ser preenchidos.' TYPE 'E'.
    RETURN.
    
  ENDIF.

  SELECT *
    FROM /gfxdsi/cct006
    INTO TABLE @DATA(lt_cct006)
    WHERE empresa IN p_empresa
      AND filial IN p_filial
      AND cliente IN p_cliente
      AND num_documento IN p_num_d
      AND item IN p_item
      AND ano IN p_ano.

  IF sy-subrc NOT INITIAL.
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

  UPDATE /gfxdsi/cct006 SET
          status         = space,
          num_compensado = space,
          ano_compensado = space,
          num_estorno    = space,
          ano_estorno    = space
    WHERE empresa IN p_empresa
      AND filial IN p_filial
      AND cliente IN p_cliente
      AND num_documento IN p_num_d
      AND item IN p_item
      AND ano IN p_ano.

  UPDATE /gfxdsi/cct006 SET data_venda = p_data_v
    WHERE empresa IN p_empresa
      AND filial IN p_filial
      AND cliente IN p_cliente
      AND num_documento IN p_num_d
      AND item IN p_item
      AND ano IN p_ano.

  DELETE FROM /gfxdsi/cct007 WHERE ... " Specify conditions
  DELETE FROM /gfxdsi/cct008 WHERE ... " Specify conditions
  DELETE FROM /gfxdsi/cct009 WHERE ... " Specify conditions
