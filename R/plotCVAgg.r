#' plotCVAgg
#' Plots the results of a CVA
#' @param respcagg res of PCA gg
#' @param type "ind" for individual graph,"distanceBiplot" for biplot,  "var" for variable graph,"cor" for univariate correlations in decreasing order with the PCA axes
#' @param text Boolean indicating whether the labels should be displayed (TRUE) or not (FALSE)
#' @param n number of variables to be selected in correlation graph (when type="cor")
#' @param colorInd if type(respcagg)="raw", this parameter allows to color the individuals according to a letter in the name of individual. It can be the first one (with "first") or another subset of character ("substr") defined in substrVec
#' @param substrVec vector of two numbers representing the two limit positions of characters to be selected when colorInd="substr"
#' @param axes c(1,2). Axes to be plotted
#' @param indSup "ell","points" or "none"
#' @param repel if TRUE, ggrepel is used to place the labels
#' @param revertX if TRUE the xaxis is reverted
#' @param revertY if TRUE the yaxis is reverted
#' @param sizeText number allowing to change the size of the text
#' @param segmentsHotelling if TRUE segments are displayed when the Hotelling test is not significant
#' @export
#' @importFrom ggforce geom_circle
#' @import ggplot2
#' @importFrom ggrepel geom_text_repel
#' @importFrom utils tail
plotCVAgg=function(respcagg,type="ind",text=TRUE,n=10,colorInd="all",substrVec=c(1,2),axes=c(1,2),indSup=c("ell"),repel=FALSE,revertX=FALSE,revertY=FALSE,sizeText=NULL,segmentsHotelling=TRUE)
{
  xend=yend=x=y=product=name=x0=y0=r=NULL
   if(type=="ind")
  {
    indiv=respcagg$indivCoord[respcagg$indivCoord[,"axes"]==paste(axes[1],axes[2],sep=","),]

      if(colorInd=="first")
      {
        indiv$product=substr(rownames(indiv),1,1)
      }
      if(colorInd=="substr")
      {
        indiv$product=substr(rownames(indiv),substrVec[1],substrVec[2])
      }
    if(colorInd=="all")
    {
      indiv$product=rownames(indiv)
    }
    if(colorInd=="vec")
    {
      indiv$product=substrVec
    }
    indiv$name=rownames(indiv)

    if(text)
    {
      gg=ggplot(indiv,aes(x=x,y=y,color=product,label=name))+   geom_text()+     theme_bw()+     geom_hline(yintercept=0)+     geom_vline(xintercept=0)
    }
    if(!text)
    {
      gg=ggplot(indiv,aes(x=x,y=y,color=product,label=name))+   geom_point()+     theme_bw()+     geom_hline(yintercept=0)+     geom_vline(xintercept=0)
    }

      if("ell"%in%indSup)
      {
        indivEll=respcagg$indivEllipsesCoord[respcagg$indivEllipsesCoord[,"axes"]==paste(axes[1],axes[2],sep=","),]
        gg=gg+geom_path(data = indivEll,aes(x=x,y=y,name=name,color=name))

      }
       if("points"%in%indSup)
      {
         indsupdat=respcagg$indSup
         indsupdat[,"name"]=paste0(indsupdat[,"subject"],"_",indsupdat[,"product"])
         gg=gg+geom_point(data=indsupdat,aes(x=x,y=y,color=product,name=name),size=1)
      }
    if(segmentsHotelling)
    {
      hotelling=respcagg$hotelling
      segHot=data.frame()
      k=0
      for(i in colnames(hotelling))
      {
        for(j in colnames(hotelling))
        {
          if(j!=i)
          {
            if(hotelling[i,j]>0.05)
            {
              segHot=rbind(segHot,c(x=respcagg$indivCoord[i,"x"],y=respcagg$indivCoord[i,"y"],xend=respcagg$indivCoord[j,"x"],yend=respcagg$indivCoord[j,"y"]))
              k=k+1
            }
          }

        }

      }
      if(k>0)
      {
        colnames(segHot)=c("x","y","xend","yend")
        gg=gg+geom_segment(data=segHot,aes(x=x,y=y,xend=xend,yend=yend))

      }
    }

     pct_x=100*respcagg$eigenValues[axes[1]]/sum(respcagg$eigenValues)
     pct_y=100*respcagg$eigenValues[axes[2]]/sum(respcagg$eigenValues)
     xlab=paste0("Axis",axes[1]," (",round(pct_x,digits=2),"%)")
     ylab=paste0("Axis",axes[2]," (",round(pct_y,digits=2),"%)")
     gg=gg+xlab(xlab)+ylab(ylab) #+ggtitle(paste0("Individual map (", round(pct_x+pct_y,digits=2),"%)"))

     gg=gg+ggtitle(paste0("CVA Individual map (",round(pct_x+pct_y,digits=2),"%, F=",round(as.numeric(respcagg$stats$F),digits=2),", pval=",round(as.numeric(respcagg$stats$pval),digits=3),",NdimSig=",respcagg$nbDimSig),")")

    return(gg)
  }

  if(type=="var")
  {
    circle <- data.frame( x0 =0,  y0 = 0,  r =1)

    if(text)
    {
      indiv=respcagg$varCoord[respcagg$varCoord[,"axes"]==paste(axes[1],axes[2],sep=","),]
      gg=ggplot(indiv,aes(x=x,y=y,name=name,label=name))+
        geom_text_repel()+
        geom_point()+
        theme_bw()+
        geom_hline(yintercept=0)+
        geom_vline(xintercept=0)+ggforce::geom_circle(data=circle,aes(x0=x0,y0=y0,r=r),color="grey",inherit.aes=FALSE)+ggtitle("Variable map")
    }
    if(!text)
    {
      indiv=respcagg$varCoord[respcagg$varCoord[,"axes"]==paste(axes[1],axes[2],sep=","),]
      gg=ggplot(indiv,aes(x=x,y=y,name=name,label=name))+
        geom_point()+
        theme_bw()+
        geom_hline(yintercept=0)+
        geom_vline(xintercept=0)+ggforce::geom_circle(data=circle,aes(x0=x0,y0=y0,r=r),color="grey",inherit.aes=FALSE)+ggtitle("Variable map")
    }
    return(gg)
  }

  if(type=="distanceBiplot")
  {
    if(!respcagg$representation%in%c("DistanceBiplot","distanceBiplot")){stop("type='biplot' possible only when respcagg was run with representation='DistanceBiplot' or 'distanceBiplot'")}
    indiv=respcagg$indivCoord[respcagg$indivCoord[,"axes"]==paste(axes[1],axes[2],sep=","),]
    if(revertX){indiv[,axes[1]]=-indiv[,axes[1]]}
    if(revertY){indiv[,axes[2]]=-indiv[,axes[2]]}

    if(colorInd=="first")
    {
      indiv$product=substr(rownames(indiv),1,1)
    }
    if(colorInd=="substr")
    {
      indiv$product=substr(rownames(indiv),substrVec[1],substrVec[2])
    }
    if(colorInd=="all")
    {
      indiv$product=rownames(indiv)
    }
    if(colorInd=="vec")
    {
      indiv$product=substrVec
    }
    indiv$name=rownames(indiv)
    gg=ggplot(indiv,aes(x=x,y=y,color=product,label=name))

    pct_x=100*respcagg$eigenValues[axes[1]]/sum(respcagg$eigenValues)
    pct_y=100*respcagg$eigenValues[axes[2]]/sum(respcagg$eigenValues)
    xlab=paste0("Axis",axes[1]," (",round(pct_x,digits=2),"%)")
    ylab=paste0("Axis",axes[2]," (",round(pct_y,digits=2),"%)")
    gg=gg+xlab(xlab)+ylab(ylab) +ggtitle(paste0("Biplot (", round(pct_x+pct_y,digits=2),"%)"))
    vardf=respcagg$varCoord[respcagg$varCoord[,"axes"]==paste(axes[1],axes[2],sep=","),]

    if(revertX){vardf[,axes[1]]=-vardf[,axes[1]]}
    if(revertY){vardf[,axes[2]]=-vardf[,axes[2]]}
    gg=gg+
      #geom_text_repel()+
      theme_bw()+
      geom_hline(yintercept=0,color="grey")+
      geom_vline(xintercept=0,color="grey")

    if(is.null(sizeText)){gg=gg+  geom_text(data=vardf,aes(x=x,y=y,label=name),color="bisque4")    }else{gg=gg+        geom_text(data=vardf,aes(x=x,y=y,label=name),color="bisque4",size=sizeText)    }
    dataSegment=as.data.frame(vardf[,c("x","y")])
    dataSegment[,"xend"]=0
    dataSegment[,"yend"]=0

    # gg=gg+geom_segment(data=dataSegment,aes(x=x,y=y,xend=xend,yend=yend),color="bisque4",inherit.aes=F)

    if(text)
    {
      gg=gg +     theme_bw()+     geom_hline(yintercept=0)+     geom_vline(xintercept=0)
      if(is.null(sizeText)){gg=gg+  geom_text()}else{gg=gg+  geom_text(size=sizeText)}

    }
    if(!text)
    {
      gg=gg +   geom_point()+     theme_bw()+     geom_hline(yintercept=0)+     geom_vline(xintercept=0)
    }

      if("ell"%in%indSup)
      {
        indivEll=respcagg$indivEllipsesCoord[respcagg$indivEllipsesCoord[,"axes"]==paste(axes[1],axes[2],sep=","),]
        if(revertX){indivEll[,"x"]=-indivEll[,"x"]}
        if(revertY){indivEll[,"y"]=-indivEll[,"y"]}
        gg=gg+geom_path(data = indivEll,aes(x=x,y=y,color=name))

      }
      if("points"%in%indSup)
      {
        indsupdat=respcagg$indSup
        colnames(indsupdat)=c("x","y","subject","product","axes")
        indsupdat[,"name"]=paste0(indsupdat[,"subject"],"_",indsupdat[,"product"])
        if(revertX){indsupdat[,"x"]=-indsupdat[,"x"]}
        if(revertY){indsupdat[,"y"]=-indsupdat[,"y"]}
        gg=gg+geom_point(data=indsupdat,aes(x=x,y=y,color=product),size=1)
      }
      if(segmentsHotelling)
      {

        k=0
        hotelling=respcagg$hotelling
        segHot=data.frame()
        for(i in colnames(hotelling))
        {
          for(j in colnames(hotelling))
          {
            if(j!=i)
            {
              if(hotelling[i,j]>0.05)
              {
                segHot=rbind(segHot,c(x=respcagg$indivCoord[i,"x"],y=respcagg$indivCoord[i,"y"],xend=respcagg$indivCoord[j,"x"],yend=respcagg$indivCoord[j,"y"]))
                k=k+1
              }
            }

          }

        }
        if(k>0)
        {

          colnames(segHot)=c("x","y","xend","yend")
          gg=gg+geom_segment(data=segHot,aes(x=x,y=y,xend=xend,yend=yend))

        }
      }

    gg=gg+ggtitle(paste0("CVA biplot (",round(pct_x+pct_y,digits=2),"%, F=",round(as.numeric(respcagg$stats$F),digits=2),", pval=",round(as.numeric(respcagg$stats$pval),digits=3),",NdimSig=",respcagg$nbDimSig,")"))

   return(gg)
  }

  if(type=="cor1")
  {
    varcor=respcagg$varCoord[respcagg$varCoord[,"axes"]==paste(axes[1],axes[2],sep=","),]
    varcor_order1=varcor[order(abs(varcor[,"x"]),decreasing=F),]
    varcor_order1[,"name"]=factor(varcor_order1[,"name"],levels=varcor_order1[,"name"])
    gg3=ggplot2::ggplot(data=tail(varcor_order1,n=n),ggplot2::aes(x = x, y = name))+ggplot2::geom_col()+ggplot2::ggtitle(paste0("Best correlations with axis ",axes[1]))+ggplot2::theme_bw()
    return(gg3)
  }
  if(type=="cor2")
  {
    varcor=respcagg$varCoord[respcagg$varCoord[,"axes"]==paste(axes[1],axes[2],sep=","),]
    varcor_order2=varcor[order(abs(varcor[,"y"]),decreasing=F),]
    varcor_order2[,"name"]=factor(varcor_order2[,"name"],levels=varcor_order2[,"name"])
    gg4=ggplot2::ggplot(data=tail(varcor_order2,n=n),ggplot2::aes(x = y, y = name))+ggplot2::geom_col()+ggplot2::ggtitle(paste0("Best correlations with axis ",axes[2]))+ggplot2::theme_bw()
    return(gg4)
  }
  if(type=="eigenValues")
  {
    dfev=data.frame(x=1:length(respcagg$eigenValues),eigen=respcagg$eigenValues)
    p=ggplot(dfev,aes(x=x,y=eigen))+geom_line()+geom_point()+theme_bw()
    return(p)
  }
}
