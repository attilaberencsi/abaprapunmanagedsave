CLASS lhc_PurchaseOrder DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PUBLIC SECTION.

    TYPES tt_return TYPE STANDARD TABLE OF bapiret2.

    CLASS-METHODS create_purchase_order
      IMPORTING
        VALUE(po_entity)         TYPE ZI_RAP_PurchaseOrder_M
        VALUE(as_test_run)       TYPE abap_bool DEFAULT abap_true
      EXPORTING
        VALUE(return)            TYPE tt_return
        VALUE(po_header_created) TYPE bapimepoheader.

    CLASS-METHODS delete_purchase_order
      IMPORTING
        VALUE(po_number)   TYPE ZI_RAP_PurchaseOrder_M-PurchaseOrder
        VALUE(as_test_run) TYPE abap_bool DEFAULT abap_true
      EXPORTING
        VALUE(return)      TYPE tt_return.

    CLASS-METHODS class_constructor.

  PRIVATE SECTION.

    TYPES: BEGIN OF ts_po_org_data,
             purch_org TYPE ZI_RAP_PurchaseOrder_M-PurchasingOrganization,
             pur_group TYPE ZI_RAP_PurchaseOrder_M-PurchasingGroup,
             plant     TYPE I_PurchaseOrderItemAPI01-Plant,
           END OF ts_po_org_data.

    "! Materialdaten zur Bestell-Schnellerfassung
    CLASS-DATA gt_material_cust TYPE TABLE OF ZI_RAP_PO_Material.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR PurchaseOrder RESULT result.

    METHODS initOrgData FOR DETERMINE ON MODIFY
      IMPORTING keys FOR PurchaseOrder~initOrgData.

    METHODS initMaterialRelatedData FOR DETERMINE ON MODIFY
      IMPORTING keys FOR PurchaseOrder~initMaterialRelatedData.

    METHODS validatePurchaseOrder FOR VALIDATE ON SAVE
      IMPORTING keys FOR PurchaseOrder~validatePurchaseOrder.

    METHODS validateMaterial FOR VALIDATE ON SAVE
      IMPORTING keys FOR PurchaseOrder~validateMaterial.

    METHODS validateOnDelete FOR VALIDATE ON SAVE
      IMPORTING keys FOR PurchaseOrder~validateOnDelete.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE purchaseorder.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK purchaseorder.

    METHODS read_baseunit_by_material
      IMPORTING
        VALUE(material)           TYPE I_Material-Material
      RETURNING
        VALUE(material_base_unit) TYPE I_Material-MaterialBaseUnit.

    CLASS-METHODS read_supplier_by_material
      IMPORTING
        VALUE(material) TYPE ZI_RAP_PurchaseOrder_M-Material
      RETURNING
        VALUE(supplier) TYPE ZI_RAP_PO_Material-Supplier.

    CLASS-METHODS read_cust_by_material
      IMPORTING
        VALUE(material)      TYPE ZI_RAP_PurchaseOrder_M-Material
      EXPORTING
        VALUE(material_cust) TYPE ZI_RAP_PO_Material.

    CLASS-METHODS read_org_data
      RETURNING
        VALUE(org_data) TYPE ts_po_org_data.

ENDCLASS.

CLASS lhc_PurchaseOrder IMPLEMENTATION.


  METHOD class_constructor.
    SELECT * FROM ZI_RAP_PO_Material
        INTO TABLE @gt_material_cust.
  ENDMETHOD.

  METHOD read_supplier_by_material.
    read_cust_by_material(
      EXPORTING
        material      = material
      IMPORTING
        material_cust = DATA(material_cust) ).
    supplier = material_cust-Supplier.
  ENDMETHOD.

  METHOD read_cust_by_material.
    READ TABLE gt_material_cust
        WITH KEY Material = material
        INTO material_cust.
  ENDMETHOD.

  METHOD read_org_data.
    org_data = VALUE #( purch_org = '1010' plant = '1010' pur_group = '001' ).
  ENDMETHOD.

  METHOD get_instance_authorizations.

    READ ENTITY ZI_RAP_PurchaseOrder_M
      ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(pos_for_auth_check).

    " 02 - Ändern => Ist löschen erlaubt
    LOOP AT pos_for_auth_check ASSIGNING FIELD-SYMBOL(<po_for_auth_check>).

      AUTHORITY-CHECK OBJECT 'M_BEST_EKO'
        ID 'EKORG' FIELD <po_for_auth_check>-PurchasingOrganization
        ID 'ACTVT' FIELD '02'.
      IF sy-subrc <> 0.
        APPEND VALUE #( PurchaseOrder = <po_for_auth_check>-PurchaseOrder
                        %delete = if_abap_behv=>auth-unauthorized ) TO result.
        CONTINUE.
      ENDIF.

      AUTHORITY-CHECK OBJECT 'M_BEST_EKG'
        ID 'EKGRP' FIELD <po_for_auth_check>-PurchasingGroup
        ID 'ACTVT' FIELD '02'.
      IF sy-subrc <> 0.
        APPEND VALUE #( PurchaseOrder = <po_for_auth_check>-PurchaseOrder
                        %delete = if_abap_behv=>auth-unauthorized ) TO result.
        CONTINUE.
      ENDIF.

      AUTHORITY-CHECK OBJECT 'M_BEST_BSA'
        ID 'BSART' FIELD <po_for_auth_check>-PurchaseOrderType
        ID 'ACTVT' FIELD '02'.
      IF sy-subrc <> 0.
        APPEND VALUE #( PurchaseOrder = <po_for_auth_check>-PurchaseOrder
                        %delete = if_abap_behv=>auth-unauthorized ) TO result.
        CONTINUE.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD initOrgData.
    DATA(org_data) = read_org_data( ).
    MODIFY ENTITIES OF ZI_RAP_PurchaseOrder_M IN LOCAL MODE
      ENTITY PurchaseOrder
        UPDATE FROM
         VALUE #( FOR k IN keys
                    ( %tky = k-%tky
                      PurchasingOrganization = org_data-purch_org
                      PurchasingGroup = org_data-pur_group
                      Plant = org_data-plant
                      %control-PurchasingOrganization = if_abap_behv=>mk-on
                      %control-PurchasingGroup = if_abap_behv=>mk-on
                      %control-Plant = if_abap_behv=>mk-on ) ).
  ENDMETHOD.

  METHOD initMaterialRelatedData.
    READ ENTITY ZI_RAP_PurchaseOrder_M
        ALL FIELDS
          WITH CORRESPONDING #( keys )
        RESULT DATA(po_headers).

    MODIFY ENTITIES OF ZI_RAP_PurchaseOrder_M IN LOCAL MODE
      ENTITY PurchaseOrder
        UPDATE FROM
         VALUE #( FOR po IN po_headers
                    ( %tky = po-%tky
                      Supplier = read_supplier_by_material( material = po-material )
                      PurchaseOrderItem = '10'
                      PurchaseOrderQuantityUnit = read_baseunit_by_material( material = po-material )
                      %control-Supplier = if_abap_behv=>mk-on
                      %control-PurchaseOrderItem = if_abap_behv=>mk-on
                      %control-PurchaseOrderQuantityUnit = if_abap_behv=>mk-on ) ).

  ENDMETHOD.

  METHOD validatePurchaseOrder.

    DATA mandatory_field_missing TYPE abap_bool.

    READ ENTITIES OF ZI_RAP_PurchaseOrder_M IN LOCAL MODE
      ENTITY PurchaseOrder
        ALL FIELDS WITH CORRESPONDING #( keys )
          RESULT DATA(pos_to_create).

    LOOP AT pos_to_create ASSIGNING FIELD-SYMBOL(<po_to_create>).

      CLEAR mandatory_field_missing.

      " Muss-Felder prüfen
      IF <po_to_create>-OrderQuantity IS INITIAL.
        failed-purchaseorder = VALUE #( BASE failed-purchaseorder
                                        ( %tky = <po_to_create>-%tky
                                          %create = if_abap_behv=>mk-on ) ).
        reported-purchaseorder = VALUE #( BASE reported-purchaseorder
                                          ( %tky = <po_to_create>-%tky
                                            %element-orderquantity = if_abap_behv=>mk-on
                                            %msg = me->new_message( severity = if_abap_behv_message=>severity-error
                                                                    id       = 'ZRAP_PO'
                                                                    number   = '003' ) ) ).
        mandatory_field_missing = abap_true.
      ENDIF.

      IF <po_to_create>-Material IS INITIAL.
        failed-purchaseorder = VALUE #( BASE failed-purchaseorder
                                        ( %tky = <po_to_create>-%tky
                                          %create = if_abap_behv=>mk-on ) ).
        reported-purchaseorder = VALUE #( BASE reported-purchaseorder
                                          ( %tky = <po_to_create>-%tky
                                            %element-material = if_abap_behv=>mk-on
                                            %msg = me->new_message( severity = if_abap_behv_message=>severity-error
                                                                    id       = 'ZRAP_PO'
                                                                    number   = '004' ) ) ).
        mandatory_field_missing = abap_true.
      ENDIF.

      IF mandatory_field_missing = abap_true.
        CONTINUE.
      ENDIF.

      create_purchase_order(
        EXPORTING
          as_test_run = abap_true        " Nur im Testlauf für Validierung der Daten
          po_entity   = CORRESPONDING #( <po_to_create> )
        IMPORTING
          return      = DATA(return) ).

      " Fehlersituation melden
      READ TABLE return
        WITH KEY type = 'E'
        TRANSPORTING NO FIELDS.
      IF sy-subrc EQ 0.
        " Create-Operation als fehlgeschlagen melden
        failed-purchaseorder = VALUE #( BASE failed-purchaseorder
                                        ( %tky = <po_to_create>-%tky
                                          %create = if_abap_behv=>mk-on ) ).
        " Fehlermeldungen zurückliefern
        reported-purchaseorder = VALUE #( BASE reported-purchaseorder
                                          FOR r IN return WHERE ( type = 'E' )
                                          ( PurchaseOrder = <po_to_create>-PurchaseOrder
                                            %msg = me->new_message( id = r-id
                                                                    number = r-number
                                                                    severity = if_abap_behv_message=>severity-error
                                                                    v1 = r-message_v1
                                                                    v2 = r-message_v2
                                                                    v3 = r-message_v3
                                                                    v4 = r-message_v4 ) ) ).
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateMaterial.

    READ ENTITIES OF ZI_RAP_PurchaseOrder_M IN LOCAL MODE
      ENTITY PurchaseOrder
        ALL FIELDS WITH CORRESPONDING #( keys )
          RESULT DATA(pos).

    LOOP AT pos INTO DATA(po) WHERE NOT Material IS INITIAL.

      " Auf Daten der Tabelle ZRAP_BO zugreifen
      read_cust_by_material(
        EXPORTING
          material      = po-Material
        IMPORTING
          material_cust = DATA(material_cust) ).

      IF NOT material_cust IS INITIAL.
        IF material_cust-IsActive NE abap_true.
          reported-purchaseorder = VALUE #( BASE reported-purchaseorder
                                            ( %tky = po-%tky
                                              %element-material = if_abap_behv=>mk-on
                                              %msg = me->new_message( severity = if_abap_behv_message=>severity-error
                                                                      id       = 'ZRAP_PO'
                                                                      number   = '002'
                                                                      v1 = |{ po-Material ALPHA = OUT }| ) ) ).
        ENDIF.
      ELSE.
        reported-purchaseorder = VALUE #( BASE reported-purchaseorder
                                          ( %tky = po-%tky
                                            %element-material = if_abap_behv=>mk-on
                                            %msg = me->new_message( severity = if_abap_behv_message=>severity-error
                                                                    id       = 'ZRAP_PO'
                                                                    number   = '001'
                                                                    v1 = |{ po-Material ALPHA = OUT }| ) ) ).
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD create_purchase_order.

    DATA: ls_po_header   TYPE bapimepoheader,
          ls_x_po_header TYPE bapimepoheaderx,
          lt_po_item     TYPE STANDARD TABLE OF bapimepoitem,
          ls_po_item     LIKE LINE OF lt_po_item,
          lt_x_po_item   TYPE STANDARD TABLE OF bapimepoitemx.

    " Kopfdaten zur Bestellung
    " PurchasingOrganization, PurchasingGroup, Supplier mappen
    ls_po_header = CORRESPONDING #( po_entity MAPPING FROM ENTITY ).

    ls_x_po_header-vendor    = abap_true.
    ls_x_po_header-purch_org = abap_true.
    ls_x_po_header-pur_group = abap_true.

    " Positionsdaten, nur eine Position anlegen
    " PurchaseOrderItem, Material, Plant, OrderQuantity mappen
    ls_po_item = CORRESPONDING #( po_entity MAPPING FROM ENTITY ).
    ls_po_item-net_price = '1.0'.
    APPEND ls_po_item TO lt_po_item.

    lt_x_po_item = VALUE #( ( po_item   = ls_po_item-po_item
                              net_price = abap_true
                              material  = abap_true
                              plant     = abap_true
                              quantity  = abap_true ) ).

    CALL FUNCTION 'BAPI_PO_CREATE1'
      EXPORTING
        poheader  = ls_po_header
        poheaderx = ls_x_po_header
        testrun   = as_test_run
      IMPORTING
        expheader = po_header_created
      TABLES
        return    = return
        poitem    = lt_po_item
        poitemx   = lt_x_po_item.

  ENDMETHOD.

  METHOD delete_purchase_order.

    DATA: ls_po_header   TYPE bapimepoheader,
          ls_x_po_header TYPE bapimepoheaderx.

    " Löschen bedeutet in der Bestellung ein Löschkennzeichen zu setzen
    ls_po_header-delete_ind = abap_true.
    ls_x_po_header-delete_ind = abap_true.
    CALL FUNCTION 'BAPI_PO_CHANGE'
      EXPORTING
        purchaseorder = po_number
        poheader      = ls_po_header
        poheaderx     = ls_x_po_header
        testrun       = as_test_run
      TABLES
        return        = return.

  ENDMETHOD.


  METHOD read_baseunit_by_material.
    SELECT SINGLE MaterialBaseUnit FROM I_Material
      WHERE Material = @material
      INTO  @material_base_unit.
  ENDMETHOD.

  METHOD validateOnDelete.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<k>).

      delete_purchase_order(
        EXPORTING
          po_number   = <k>-PurchaseOrder
          as_test_run = abap_true
        IMPORTING
          return      = DATA(return) ).

      " Fehlersituation melden
      READ TABLE return
        WITH KEY type = 'E'
        TRANSPORTING NO FIELDS.
      IF sy-subrc EQ 0.
        " delete-Operation als fehlgeschlagen melden
        failed-purchaseorder = VALUE #( BASE failed-purchaseorder
                                        ( PurchaseOrder = <k>-PurchaseOrder
                                          %delete = if_abap_behv=>mk-on ) ).
        " Fehlermeldungen zurückliefern
        reported-purchaseorder = VALUE #( BASE reported-purchaseorder
                                          FOR r IN return WHERE ( type = 'E' )
                                          ( PurchaseOrder = <k>-PurchaseOrder
                                            %msg = me->new_message( id = r-id
                                                                    number = r-number
                                                                    severity = if_abap_behv_message=>severity-error
                                                                    v1 = r-message_v1
                                                                    v2 = r-message_v2
                                                                    v3 = r-message_v3
                                                                    v4 = r-message_v4 ) ) ).
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD precheck_create.

    DATA(org_data) = read_org_data( ).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<po>).

      AUTHORITY-CHECK OBJECT 'M_BEST_EKO'
        ID 'EKORG' FIELD org_data-purch_org
        ID 'ACTVT' FIELD '01'.
      IF sy-subrc <> 0.
        failed-purchaseorder = VALUE #( BASE failed-purchaseorder
                                        ( %cid = <po>-%cid
                                          %create = if_abap_behv=>auth-unauthorized ) ).
        reported-purchaseorder = VALUE #( BASE reported-purchaseorder
                                          ( %cid = <po>-%cid
                                            %msg = me->new_message( severity = if_abap_behv_message=>severity-error
                                                                    id       = 'ZRAP_PO'
                                                                    number   = '005' ) ) ).
        CONTINUE.
      ENDIF.

      AUTHORITY-CHECK OBJECT 'M_BEST_EKG'
        ID 'EKGRP' FIELD org_data-pur_group
        ID 'ACTVT' FIELD '01'.
      IF sy-subrc <> 0.
        failed-purchaseorder = VALUE #( BASE failed-purchaseorder
                                        ( %cid = <po>-%cid
                                          %create = if_abap_behv=>auth-unauthorized ) ).
        reported-purchaseorder = VALUE #( BASE reported-purchaseorder
                                          ( %cid = <po>-%cid
                                            %msg = me->new_message( severity = if_abap_behv_message=>severity-error
                                                                    id       = 'ZRAP_PO'
                                                                    number   = '005' ) ) ).
        CONTINUE.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD lock.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<k>).

      CALL FUNCTION 'ENQUEUE_EMEKKOS'
        EXPORTING
          ebeln          = <k>-PurchaseOrder
        EXCEPTIONS
          foreign_lock   = 1
          system_failure = 2
          OTHERS         = 3.

      CASE sy-subrc.
        WHEN 1. " Bestellung ist bereits gesperrt
          failed-purchaseorder = VALUE #( BASE failed-purchaseorder
                                          ( purchaseorder = <k>-PurchaseOrder
                                            %fail-cause = if_abap_behv=>cause-locked
                                          ) ).
          reported-purchaseorder = VALUE #( BASE reported-purchaseorder
                                            ( purchaseorder = <k>-PurchaseOrder
                                              %msg = new_message(
                                                 id       = sy-msgid
                                                 number   = sy-msgno
                                                 severity = if_abap_behv_message=>severity-error
                                                 v1       = sy-msgv1
                                                 v2       = sy-msgv2
                                                 v3       = sy-msgv3
                                                 v4       = sy-msgv4 ) ) ).
        WHEN OTHERS.
          RAISE SHORTDUMP NEW zcx_rap_purchaseorder( textid = VALUE #( msgid = sy-msgid msgno = sy-msgno ) ).
      ENDCASE.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_RAP_PurchaseOrder_M DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS adjust_numbers REDEFINITION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_RAP_PurchaseOrder_M IMPLEMENTATION.

  METHOD adjust_numbers.
    READ ENTITIES OF ZI_RAP_PurchaseOrder_M
      ENTITY PurchaseOrder
        ALL FIELDS
          WITH CORRESPONDING #( mapped-purchaseorder )
          RESULT DATA(pos_to_create).

    LOOP AT pos_to_create INTO DATA(po_to_create).

      " Neue Bestellung anlegen
      lhc_purchaseorder=>create_purchase_order(
        EXPORTING
          as_test_run    = abap_false
          po_entity      = CORRESPONDING #( po_to_create )
        IMPORTING
          po_header_created = DATA(po_header_created)
          return            = DATA(return) ).

      READ TABLE return WITH KEY type = 'E'
        INTO DATA(return_err).
      IF sy-subrc EQ 0.
        RAISE SHORTDUMP NEW zcx_rap_purchaseorder( textid = VALUE #( msgid = return_err-id msgno = return_err-number ) ).
      ENDIF.

      " MAPPED: Schlüsselwerte zurückgeben
      APPEND INITIAL LINE TO mapped-purchaseorder
          ASSIGNING FIELD-SYMBOL(<ls_mapped>).
      <ls_mapped>-%pid = po_to_create-%pid.
      <ls_mapped>-PurchaseOrder = po_header_created-po_number.

      " REPORTED: Meldungen zurückliefern
      reported-purchaseorder = VALUE #( BASE reported-purchaseorder
                                        FOR r IN return WHERE ( type = 'I' OR type <> 'W' )
                                        ( %tky = po_to_create-%tky
                                          PurchaseOrder = po_header_created-po_number
                                          %msg = me->new_message(
                                                   id       = r-id
                                                   number   = r-number
                                                   severity = COND #( WHEN r-type = 'I'
                                                                        THEN if_abap_behv_message=>severity-information
                                                                      WHEN r-type = 'W'
                                                                        THEN if_abap_behv_message=>severity-warning )
                                                   v1       = r-message_v1
                                                   v2       = r-message_v2
                                                   v3       = r-message_v3
                                                   v4       = r-message_v4 )
                                        ) ).

    ENDLOOP.

  ENDMETHOD.

  METHOD save_modified.

    LOOP AT delete-purchaseorder ASSIGNING FIELD-SYMBOL(<po_to_delete>).

      lhc_purchaseorder=>delete_purchase_order(
        EXPORTING
          po_number   = <po_to_delete>-PurchaseOrder
          as_test_run = abap_false
        IMPORTING
          return      = DATA(return) ).

      READ TABLE return WITH KEY type = 'E'
        INTO DATA(return_err).
      IF sy-subrc EQ 0.
        RAISE SHORTDUMP NEW zcx_rap_purchaseorder( textid = VALUE #( msgid = return_err-id msgno = return_err-number ) ).
      ENDIF.

      " Meldungen zurückliefern
      reported-purchaseorder = VALUE #( BASE reported-purchaseorder
                                        FOR r IN return WHERE ( type = 'I' OR type <> 'W' )
                                        ( PurchaseOrder = <po_to_delete>-PurchaseOrder
                                          %msg = me->new_message(
                                                   id       = r-id
                                                   number   = r-number
                                                   severity = COND #( WHEN r-type = 'I' THEN if_abap_behv_message=>severity-information
                                                                      WHEN r-type = 'W' THEN if_abap_behv_message=>severity-warning )
                                                   v1       = r-message_v1
                                                   v2       = r-message_v2
                                                   v3       = r-message_v3
                                                   v4       = r-message_v4 )
                                        ) ).

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
