*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Tables
Library             OperatingSystem
Library             RPA.Desktop
Library             RPA.Dialogs
Library             RPA.Archive
Library             Collections
Library             RPA.Robocloud.Secrets
Library             RPA.RobotLogListener


*** Variables ***
${url}              https://robotsparebinindustries.com
${img_folder}       ${CURDIR}${/}image_files
${pdf_folder}       ${CURDIR}${/}pdf_files
${output_folder}    ${CURDIR}${/}output

${orders_file}      ${CURDIR}${/}orders.csv
${zip_file}         ${output_folder}${/}pdf_archive.zip
${csv_file}         https://robotsparebinindustries.com/orders.csv


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Directory Cleanup
    Open the order website
    Log in
    Download the csv file
    Fill the form using data from excel


*** Keywords ***
Directory Cleanup
    Create Directory    ${output_folder}
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}

    Empty Directory    ${img_folder}
    Empty Directory    ${pdf_folder}

Open the order website
    Open Available Browser    ${url}

Log in
    Input Text    username    maria
    Input Text    password    thoushallnotpass
    Submit Form
    Wait Until Page Contains Element    id:sales-form
    Click Element    css:#root > header > div > ul > li:nth-child(2) > a
    Click Button    OK

Download the csv file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Fill the form using data from excel
    ${orders_data} =    Read table from CSV    ${CURDIR}${/}orders.csv    header=True
    FOR    ${row}    IN    @{orders_data}
        Close the annoying modal
        Log    ${row}
        Wait Until Element Is Visible    id:preview
        Fill the form    ${row}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit the Order
        ${order_id}    ${img_filename} =    Take screenshot of preview order
        ${pdf_filename} =    Store the receipt as PDF file    ORDER_NUMBER=${order_id}
        Embed Screenshot into PDF File    IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}
        Go to order another robot
    END
    Create a zip file of the receipts
    Log out and close the Browser

Close the annoying modal
    Set Local Variable    ${btn_yes}    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
    ${check_element} =    Run Keyword And Return Status    Wait Until Page Contains Element    ${btn_yes}    10s
    Log To Console    ${check_element}
    IF    ${check_element} == 'True'    Click Element    ${btn_yes}

Fill the form
    [Arguments]    ${row}

    Log To Console    ${row}
    Set Local Variable    ${order_no}    ${row}[Order number]
    Set Local Variable    ${legs}    ${row}[Legs]
    Set Local Variable    ${body}    ${row}[Body]
    Set Local Variable    ${head}    ${row}[Head]
    Set Local Variable    ${address}    ${row}[Address]

    Set Local Variable    ${input_head}    //*[@id="head"]
    Set Local Variable    ${input_body}    body
    Set Local Variable    ${input_legs}    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable    ${input_address}    //*[@id="address"]

    Wait Until Element Is Visible    ${input_head}
    Wait Until Element Is Enabled    ${input_head}
    Select From List By Value    ${input_head}    ${head}

    Wait Until Element Is Enabled    ${input_legs}
    Input Text    ${input_legs}    ${legs}

    Wait Until Element Is Enabled    ${input_address}
    Input Text    ${input_address}    ${address}

    Wait Until Element Is Enabled    ${input_body}
    Select Radio Button
    ...    ${input_body}
    ...    ${body}

Preview the robot
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]
    Click Button    ${btn_preview}
    Wait Until Element Is Visible    ${img_preview}

Submit the Order
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${lbl_receipt}    //*[@id="receipt"]

    Mute Run On Failure    Page Should Contain Element

    Click Button    ${btn_order}
    Page Should Contain Element    ${lbl_receipt}

Take screenshot of preview order
    Set Local Variable    ${lbl_orderid}    xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable    ${img_robot}    //*[@id="robot-preview-image"]

    Wait Until Element Is Visible    ${img_robot}
    Wait Until Element Is Visible    ${lbl_orderid}

    #get order id for file name
    ${orderid} =    Get Text    //*[@id="receipt"]/p[1]

    Set Local Variable    ${fully_qualified_img_filename}    ${img_folder}${/}${orderid}.png

    Sleep    1sec
    Log To Console    Capturing Screenshot to ${fully_qualified_img_filename}
    Capture Element Screenshot    ${img_robot}    ${fully_qualified_img_filename}

    Screenshot    css:div.row    ${OUTPUT_DIR}${/}preview_order.png
    RETURN    ${orderid}    ${fully_qualified_img_filename}

Go to order another robot
    Set Local Variable    ${btn_order_another_robot}    //*[@id="order-another"]
    Click Button    ${btn_order_another_robot}

Log out and close the Browser
    Close Browser

Create a zip file of the receipts
    Archive Folder With Zip    ${pdf_folder}    ${zip_file}    recursive=True    include=*.pdf

Store the receipt as PDF file
    [Arguments]    ${ORDER_NUMBER}

    Wait Until Element Is Visible    //*[@id="receipt"]
    ${order_receipt_html} =    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Set Local Variable    ${fully_qualified_pdf_filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf

    Html To Pdf    content=${order_receipt_html}    output_path=${fully_qualified_pdf_filename}

    RETURN    ${fully_qualified_pdf_filename}

Embed Screenshot into PDF File
    [Arguments]    ${IMG_FILE}    ${PDF_FILE}

    Open Pdf    ${PDF_FILE}
    @{my_files} =    Create List    ${IMG_FILE}:x=0,y=0

    Add Files To Pdf    ${my_files}    ${PDF_FILE}    ${True}

    Close Pdf

Export Table as PDF
    ${order_completion_html} =    Get Element Attribute    id:order-completion    outerHTML
    Take screenshot of preview order
    Html To Pdf
    ...    ${OUTPUT_DIR}${/}order_completion.pdf
    ...    overwrite=True
    ${files} =    Create List    ${OUTPUT_DIR}${/}order_completion.pdf    ${OUTPUT_DIR}${/}preview_order.png
    Add Files To Pdf    ${files}    order.pdf
