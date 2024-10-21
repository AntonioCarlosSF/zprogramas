METHOD efetua_lancamento_pix.

  DATA: lv_auglv    TYPE t041a-auglv VALUE 'EINGZAHL', " Código de Lançamento para Pagamento
        lv_tcode    TYPE sy-tcode VALUE 'FB05',        " Transação que vai rodar
        lv_sgfunct  TYPE rfipi-sgfunct VALUE 'C',      " Post immediately
        lv_cont     TYPE i,
        lv_item     TYPE buzei,
        lv_mode     TYPE char1 VALUE 'N',
        lv_zuonr    TYPE /gfxdsi/eatrib,
        lv_blart    TYPE blart,
        lv_data_arq TYPE bkpf-budat,
        lv_msg      TYPE /gfxdsi/emsglog,
        lv_doc_type TYPE blart.

  DATA: lt_blntab  TYPE STANDARD TABLE OF blntab,
        ls_blntab  LIKE LINE OF lt_blntab,
        lt_ftclear TYPE STANDARD TABLE OF ftclear,
        ls_ftclear LIKE LINE OF lt_ftclear,
        lt_ftpost  TYPE STANDARD TABLE OF ftpost,
        ls_ftpost  LIKE LINE OF lt_ftpost,
        lt_fttax   TYPE STANDARD TABLE OF fttax,
        lt_cct006  TYPE TABLE OF /gfxdsi/cct006,
        ls_fttax   LIKE LINE OF lt_fttax,
        ls_cct003  TYPE /gfxdsi/cct003,
        ls_cce006  TYPE /gfxdsi/cct006,
        ls_message TYPE /gfxdsi/ccemsg_ty,
        ls_cce008  TYPE /gfxdsi/cct008.

  " Field-Symbols
  FIELD-SYMBOLS: <fs_007> TYPE /gfxdsi/cce007_ty,
                 <fs_008> TYPE /gfxdsi/cce008_ty.

  " Procura dados na tabela /gfxdsi/cct006
  SELECT *
    FROM /gfxdsi/cct006
    INTO TABLE lt_cct006
    FOR ALL ENTRIES IN gt_cct008
    WHERE empresa        EQ gt_cct008-empresa
      AND filial         EQ gt_cct008-filial
      AND cliente        EQ gt_cct008-cliente
      AND num_documento  EQ gt_cct008-num_documento
      AND item           EQ gt_cct008-item
      AND ano            EQ gt_cct008-ano
      AND num_parcela    EQ gt_cct008-num_parcela
      AND tot_parcelas   EQ gt_cct008-tot_parcelas
      AND chave_bandeira EQ gt_cct008-chave_band
      AND id_pix         EQ gt_cct008-id_pix
      AND ( ( nsu        EQ gt_cct008-nsu AND nsu <> '' AND nsu IS NOT NULL )
         OR   ( tid        EQ gt_cct008-tid AND tid <> '' AND tid IS NOT NULL )
         OR   ( cod_aut    EQ gt_cct008-cod_autoriz AND cod_aut <> '' AND cod_aut IS NOT NULL ) )
      AND status         NE 'ES'
      AND num_estorno    EQ ''.

  " Seleciona tipo de documento cadastrado nas configurações
  SELECT SINGLE doc_cv
    FROM /gfxdsi/cct016
    INTO lv_doc_type
    WHERE doc_cv IS NOT NULL.

  LOOP AT gt_cct008 ASSIGNING <fs_008>.
    FREE lv_data_arq.
    UNASSIGN <fs_007>.
    READ TABLE gt_cct007 ASSIGNING <fs_007> WITH KEY index = <fs_008>-indexro.

    " Se não tiver encontrado o RO na linha acima vai para o próximo CV
    IF sy-subrc IS NOT INITIAL.
      CONTINUE.
    ENDIF.

    LOOP AT lt_cct006 INTO ls_cce006.

      IF checa_documento_compensado( iv_bukrs = <fs_008>-empresa
                                   iv_belnr = <fs_008>-num_documento
                                   iv_gjahr = <fs_008>-ano
                                   iv_buzei = <fs_008>-item ) EQ abap_true.
        CONTINUE.
      ELSE.
        " Checa se a opção de lançar com perid. conta. fechado está marcada
        IF gs_cct016-pc_fechado EQ ''.

          " Checa se o periodo contábil está fechado
          IF checa_periodo_contabil( i_data_lanc = <fs_008>-data_efet
                                     i_tpconta   = '+'
                                     i_empresa   = <fs_007>-empresa ) EQ abap_false.

            " Se sim, seta o RO e seus respectivos CV como pendente
            set_periodo_c_fechado( CHANGING c_cce007 = <fs_007>
                                            c_cce008 = <fs_008> ).
            CONTINUE.

          ENDIF.

        ELSE.

          " Checa se o perído contábil está fechado
          IF checa_periodo_contabil( i_data_lanc = <fs_008>-data_efet
                                     i_tpconta   = '+'
                                     i_empresa   = <fs_007>-empresa ) EQ abap_false.

            " Se sim, lança o documento com a data atual
            lv_data_arq = <fs_008>-data_arq.

          ENDIF.

        ENDIF.
     ENDIF.

        CLEAR: lt_blntab,
               ls_blntab,
               lt_ftclear,
               ls_ftclear,
               lt_ftpost,
               ls_ftpost,
               lt_fttax,
               ls_fttax.

        CALL FUNCTION 'POSTING_INTERFACE_START'
          EXPORTING
            i_function         = 'C'
            i_mode             = lv_mode " Especialista
            i_user             = sy-uname
          EXCEPTIONS
            client_incorrect   = 1
            function_invalid   = 2
            group_name_missing = 3
            mode_invalid       = 4
            update_invalid     = 5
            OTHERS             = 6.

        " Seleciona dados de Contab.financ.
        SELECT SINGLE atribuicao
              FROM /gfxdsi/cct003
              INTO lv_zuonr
              WHERE empresa    EQ <fs_007>-empresa    AND
                    filial     EQ <fs_007>-filial     AND
                    chave_band EQ <fs_007>-chave_band.

        SELECT SINGLE *
         INTO CORRESPONDING FIELDS OF ls_cct003
         FROM /gfxdsi/cct003
         WHERE empresa    EQ <fs_008>-empresa    AND
               filial     EQ <fs_008>-filial      AND
               chave_band EQ <fs_008>-chave_band AND
               cliente    EQ <fs_008>-cliente    AND
               cod_estab  EQ <fs_007>-cod_estab.

 "       **********************************************************************
 "       *** Montando o cabeçalho
"        **********************************************************************
        CLEAR lv_cont.
        ADD 1 TO lv_cont.

        " Montando Cabeçalho
        ls_ftpost-stype = 'K'. " Tipo Cabeçalho (K)
        ls_ftpost-count = lv_cont. " Número da Tela
        " Empresa
        ls_ftpost-fnam = 'BKPF-BUKRS'.
        ls_ftpost-fval = ls_cce006-empresa. " mUDAT 06
        APPEND ls_ftpost TO lt_ftpost.

        " Data do documento
        ls_ftpost-fnam = 'BKPF-BLDAT'.
        ls_ftpost-fval = lv_data_arq.
        APPEND ls_ftpost TO lt_ftpost.

        " Data do lançamento
        ls_ftpost-fnam = 'BKPF-BUDAT'.
        ls_ftpost-fval = lv_data_arq.
        APPEND ls_ftpost TO lt_ftpost.

        " Tipo do Documento
        ls_ftpost-fnam = 'BKPF-BLART'.
        ls_ftpost-fval = lv_doc_type.
        APPEND ls_ftpost TO lt_ftpost.

        " Mês do exercício
        ls_ftpost-fnam = 'BKPF-MONAT'.
        ls_ftpost-fval = ls_cce006-ano.
        APPEND ls_ftpost TO lt_ftpost.

        " Moeda
        ls_ftpost-fnam = 'BKPF-WAERS'.
        ls_ftpost-fval = 'BRL'.
        APPEND ls_ftpost TO lt_ftpost.

        " Texto do Documento
        ls_ftpost-fnam = 'BKPF-BKTXT'.
        ls_ftpost-fval = 'C2D - LANC. PIX – Data de lançamento'.
        APPEND ls_ftpost TO lt_ftpost.

        " Montando itens
        "**********************************************************************

        " Definindo Contador.
        lv_cont = lv_cont + 1.

        " Entrando Item 01
        ls_ftpost-stype = 'P'.
        ls_ftpost-count = lv_cont.

        " Campo Chave de Lançamento
        ls_ftpost-fnam = 'RF05A-NEWBS'.
        ls_ftpost-fval = '40'.
        APPEND ls_ftpost TO lt_ftpost.

        " Campo Chave de Lançamento
        ls_ftpost-fnam = 'RF05A-NEWKO'.
        ls_ftpost-fval = ls_cce006-cliente.
        APPEND ls_ftpost TO lt_ftpost.

        " Campo Estabelecimento
        ls_ftpost-fnam = 'BSEG-BUPLA'.
        ls_ftpost-fval = ls_cce006-filial.
        APPEND ls_ftpost TO lt_ftpost.

        " Campo Montante
        ls_ftpost-fnam = 'BSEG-WRBTR'.
        ls_ftpost-fval = ls_cce006-valor_venda.
        APPEND ls_ftpost TO lt_ftpost.

        " Data
        ls_ftpost-fnam = 'BSEG-VALUT'.
        ls_ftpost-fval = lv_data_arq.
        APPEND ls_ftpost TO lt_ftpost.

        " Montando item 02
        lv_cont = lv_cont + 1.
        " Entrando Item 02
        ls_ftpost-stype = 'P'.
        ls_ftpost-count = lv_cont.
        APPEND ls_ftpost TO lt_ftpost.

        ls_ftpost-fnam = 'RF05A-NEWBS '.
        ls_ftpost-fval = '15'.
        APPEND ls_ftpost TO lt_ftpost.

        ls_ftpost-fnam = 'RF05A-NEWKO'.
        ls_ftpost-fval = ls_cce006-cliente.
        APPEND ls_ftpost TO lt_ftpost.

        ls_ftpost-fnam = 'BSEG-BUPLA'.
        ls_ftpost-fval = ls_cce006-cod_estab.
        APPEND ls_ftpost TO lt_ftpost.

        MULTIPLY ls_cce006-valor_venda BY -1.

        ls_ftpost-fnam = 'BSEG-WBTR'.
        ls_ftpost-fval = ls_cce006-valor_venda.
        APPEND ls_ftpost TO lt_ftpost.

        ls_ftpost-fnam = 'BSEG-HKONT'.
        ls_ftpost-fval = lv_zuonr.
        APPEND ls_ftpost TO lt_ftpost.

        " Data
        ls_ftpost-fnam = 'BSEG-VALUT'.
        ls_ftpost-fval = lv_data_arq.
        APPEND ls_ftpost TO lt_ftpost.

        " Processar PA.
        " Documents to be cleared
        ls_ftclear-agkoa = 'D'.              " Account Type
        ls_ftclear-xnops = 'X'.              " Indicator: Select only open items which are not special G/L?
        ls_ftclear-agbuk = ls_cce006-empresa. " Example company code
        ls_ftclear-agkon = <fs_008>-cliente. " Example Customer
        ls_ftclear-selfd = 'BELNR'.          " Selection Field
        ls_ftclear-agums = ''.               " Códigos de razão especial que vai ser selecionado

        " Seleciona o item de estorno
    SELECT SINGLE buzei
      FROM bsid
      INTO lv_item
      WHERE bukrs EQ ls_cce006-empresa
        AND belnr EQ ls_cce006-num_compensado
        AND gjahr EQ ls_cce006-ano_compensado.

    IF sy-subrc IS INITIAL.
      CONCATENATE ls_cce006-num_compensado ls_cce006-ano_compensado lv_item INTO ls_ftclear-selvon.
      CONCATENATE ls_cce006-num_compensado ls_cce006-ano_compensado lv_item INTO ls_ftclear-selbis.
    ELSE.
      CONCATENATE  ls_cce006-num_documento ls_cce006-ano ls_cce006-item INTO ls_ftclear-selvon.
      CONCATENATE  ls_cce006-num_documento ls_cce006-ano ls_cce006-item INTO ls_ftclear-selbis.
    ENDIF.


        APPEND ls_ftclear TO lt_ftclear.

        CALL FUNCTION 'POSTING_INTERFACE_CLEARING'
          EXPORTING
            i_auglv                    = lv_auglv
            i_tcode                    = lv_tcode
            i_sgfunct                  = lv_sgfunct
            i_no_auth                  = 'X'
          IMPORTING
            e_msgid                    = ls_message-msgid
            e_msgno                    = ls_message-w_msgno
            e_msgty                    = ls_message-w_msgty
            e_msgv1                    = ls_message-w_msgv1
            e_msgv2                    = ls_message-w_msgv2
            e_msgv3                    = ls_message-w_msgv3
            e_msgv4                    = ls_message-w_msgv4
          TABLES
            t_blntab                   = lt_blntab
            t_ftclear                  = lt_ftclear
            t_ftpost                   = lt_ftpost
            t_fttax                    = lt_fttax
          EXCEPTIONS
            clearing_procedure_invalid = 1
            clearing_procedure_missing = 2
            table_t041a_empty          = 3
            transaction_code_invalid   = 4
            amount_format_error        = 5
            too_many_line_items        = 6
            company_code_invalid       = 7
            screen_not_found           = 8
            no_authorization           = 9
            OTHERS                     = 10.

        " Lê a tabela que possui o número do documento
        CLEAR ls_blntab.
        READ TABLE lt_blntab INTO ls_blntab INDEX 1.
        IF sy-subrc EQ 0 OR ls_message-w_msgty <> 'E'.
          FREE lv_msg.
          " Documento(s) conciliado(s) com sucesso.
          MESSAGE s035(/gfxdsi/ccm001) INTO lv_msg.

          " Preenche a mensagem no log
          CONCATENATE lv_msg
                      ls_message-msg_txt
                 INTO <fs_008>-msg_status
             SEPARATED BY space.
          APPEND ls_ftclear TO lt_ftclear.

          <fs_008>-status_cv     = 'R'.    " Status conciliado
          <fs_008>-num_documento = ls_blntab-belnr.    " Documento
          <fs_008>-ano           = ls_blntab-gjahr.    " Ano
          "<fs_008>-item          = ls_blntab-.    " Item

          CALL FUNCTION 'ICON_CREATE'
            EXPORTING
              name   = icon_reject
              info   = <fs_008>-msg_status
            IMPORTING
              result = <fs_008>-status.

          " Move os dados de acordo com os parâmetros.
          FREE ls_cce008.
          MOVE-CORRESPONDING <fs_008> TO ls_cce008.

          " Modifica a tabela /GFXDSI/CCT008
          MODIFY /gfxdsi/cct008 FROM ls_cce008.
          FREE ls_cce008.

          " Atribui os novos valores
          ls_cce006-num_compensado = ls_blntab-belnr.
          ls_cce006-ano            = ls_blntab-gjahr.
          ls_cce006-status         = 'PC'. " Pagamento conciliado

          " Atualiza os dados
          MODIFY /gfxdsi/cct006 FROM ls_cce006.

          COMMIT WORK.

        ELSE.

          IF ls_message-msgid IS NOT INITIAL.
            trata_erros( CHANGING c_msg = ls_message ).
          ENDIF.

          FREE lv_msg.
          " Erro ao efetuar a conciliação do pagamento.
          MESSAGE s045(/gfxdsi/ccm001) INTO lv_msg.

          CONCATENATE lv_msg
                      ls_message-msg_txt
                 INTO ls_cce008-msg_status
             SEPARATED BY space.

          <fs_008>-status_cv = 'P'.            " Pendente

          CALL FUNCTION 'ICON_CREATE'
            EXPORTING
              name   = icon_led_red
              info   = <fs_008>-msg_status
            IMPORTING
              result = <fs_008>-status.

          " Move os dados de acordo com os parâmetros.
          FREE ls_cce008.
          MOVE-CORRESPONDING <fs_008> TO ls_cce008.

          " Modifica a tabela /GFXDSI/CCT008
          MODIFY /gfxdsi/cct008 FROM ls_cce008.
          FREE ls_cce008.

          IF ls_message-msgid IS NOT INITIAL.
            " Armazena o log de erro
            guarda_log(
              EXPORTING
                i_id         = ls_message-msgid    " Classe de mensagem
                i_number     = ls_message-w_msgno  " Nº mensagem
                i_type       = ls_message-w_msgty  " Ctg.mens.: S sucesso, E erro, W aviso, I inform., A cancel.
                i_message_v1 = ls_message-w_msgv1  " Variável mensagens
                i_message_v2 = ls_message-w_msgv2  " Variável mensagens
                i_message_v3 = ls_message-w_msgv3  " Variável mensagens
                i_message_v4 = ls_message-w_msgv4  " Variável mensagens
            ).
          ENDIF.

        ENDIF. " Fim do IF sy-subrc EQ 0 OR ls_message-w_msgty <> 'E'.

        CALL FUNCTION 'POSTING_INTERFACE_END'
          EXPORTING
            i_bdcimmed              = 'X'
          EXCEPTIONS
            session_not_processable = 1
            OTHERS                  = 2.

      ENDLOOP. " Fim do LOOP lt_cct006

    ENDLOOP. " Fim do LOOP gt_cct008
    exibe_log( ).

ENDMETHOD.
