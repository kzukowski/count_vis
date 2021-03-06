#selectedrowindex = 0

# Server.R
shinyServer(function(input, output,session) {
  options(shiny.maxRequestSize=1000*1024^2)
  
  
  fun<- function(myData){ 
    
    dane <- myData$datapath
    dane <- data.frame(read.csv(dane, sep=",", header=T))
    
    if 
    (colnames(dane)[1]=="gene_id") 
      rownames(dane) <- dane[,1]
    else
      dane <- dane
    
    if 
    (colnames(dane)[1]=="gene_id") 
    dane <- dane %>% select(-gene_id)
    else 
      dane <- dane
    
    
    return(dane)
  }
  
  
  myData <- reactive({
    inFile <- input$file1
    
    if (is.null(inFile))
      return(NULL)
    inFile
  }) 
  
  
  New_Input <- reactive({

    inFile <- input$file1
    data.frame(read.csv(input$file1$datapath))
  })
  
  
  observeEvent(input$analysis, {
    myData <- myData()

    if (is.null(myData$datapath)){
      return(NULL)
    }
    updateSelectInput(session,
                      inputId = "columns",
                      choices = names(New_Input()))
    return(myData)
  })
  
 
  
  observeEvent(input$refresh_button, {
    js$reset()
  })     


  
  sampletable <- eventReactive(input$analysis, {
    myData <- myData()

    
    if (!is.null(myData)){
      Tab <- fun(myData)
      
      return(Tab)
    }  
  })
  

  
  variable <- reactive( {

    colindex <- input$columns
    
    selectedrowindex <<- input$sampletable_rows_selected
     
    selectedrowindex <<- as.numeric(unlist(selectedrowindex))
    
    selectedrow <- (sampletable()[selectedrowindex,])
    
    selectedrow <- selectedrow[, as.numeric( c(which(colnames(selectedrow) %in% (colindex) )))]
    
    
    if(input$norm=='Norm')
      return(selectedrow<-(selectedrow-min(selectedrow))/(max(selectedrow)-min(selectedrow)))
    if(input$norm=='No_Norm')
      return(selectedrow)
  } )
  
 
  
  ##########table_messages##########
  
  
  output$tableMessage1 <- renderUI({
    myData <- myData()
    if (is.null(myData)){
      br()
      h3("Please, upload your file to show the table.")
    }
  })
  
  output$tableMessage2 <- renderUI({
    myData <- myData()
    if (is.null(myData)){
      br()
      h3("Please, select your data in the first table.")
    }
  })
 
  output$tableMessage3 <- renderUI({
    myData <- myData()
    if (is.null(myData)){
      br()
      h3("Please, select your data to show the heatmap.")
    }
  })
  
  output$tableMessage4 <- renderUI({
    myData <- myData()
    if (is.null(myData)){
      br()
      h3("Please, select your data to show the barplot.")
    }
  })
  
  
  
  ##########table##########

  
 
   output$sampletable <- DT::renderDataTable({
     
     sampletable()
    
    }, server = TRUE, selection = 'multiple')
  
  
  
  ##########new_table##########
  
  
  output$selectedrow <- DT::renderDataTable({
    
   round(variable(),2)
    
  })
 

  
  ##########barplot##########
  
  
  output$plot <- renderPlot({
    
    data2 <- cbind(variable(), rownames(variable()))
    data3 <- melt(data2)
    colnames(data3) <- c("gene", "sample", "value")
    data3 <- as.data.table(data3)
    data3$value=as.numeric(data3$value)
    
    plot_geom_bar_2 <- ggplot(data3, aes(sample , value, fill=gene) ) + 
      geom_bar(aes(fill = factor( gene)), position = "dodge", stat = "identity") 
    # facet_grid(gene ~ .)
    
    plot_geom_bar_2
    
  })
  
  
  ##########heatmap##########
  
  
  output$heatmap <- renderD3heatmap({
    
     d3heatmap(variable(), scale = "column")
    
  })

  
 
})