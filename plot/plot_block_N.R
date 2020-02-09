#!/usr/bin/env Rscript

require("argparse")
require("ggplot2")
require("scales")

parser <- ArgumentParser(description = "Make block N* or NG* plots. Applicable for scaffolds, contigs, and phased blocks.")
parser$add_argument("-b", "--block", type="character", help="sorted .sizes file", default=NULL)
parser$add_argument("-s", "--scaff", type="character", help="sorted .sizes file", default=NULL)
parser$add_argument("-c", "--contig", type="character", help="sorted .sizes file", default=NULL)
parser$add_argument("-o", "--out", type="character", help="output prefix (required) [default %(default)s]", default="out")
parser$add_argument("-g", "--gsize", type="integer", default=0, help="genome size for computing NG* (optional)")
parser$add_argument("-x", "--xdim", type="double", default=6, help="width of plot [default %(default)s]")
parser$add_argument("-y", "--ydim", type="double", default=5, help="height of plot [default %(default)s]")
parser$add_argument("-p", "--pdf", dest='pdf', default=FALSE, action='store_true', help="set to get output in .pdf. [default .png]")
args <- parser$parse_args()

fancy_scientific <- function(d) {
  # turn in to character string in scientific notation
  d <- format(d, scientific = TRUE)
  # quote the part before the exponent to keep all the digits and turn the 'e+' into 10^ format
  d <- gsub("^(.*)e\\+", "'\\1'%*%10^", d)
  # convert 0x10^00 to 0
  d <- gsub("\\'0[\\.0]*\\'(.*)", "'0'", d)
  # return this as an expression
  parse(text=d)
}

save_plot <- function(name, type, stats, outformat, h, w) {
  ggsave(file = paste(name, type, stats, outformat, sep = "."), height = h, width = w)
}

attach_n <- function(dat, gsize=0) {
  dat = read.table(dat, header = F)
  names(dat) = c("Type", "Group", "Size")
  dat$Sum = cumsum(as.numeric(dat$Size))
  
  if (gsize == 0) {
    # N*
    gsize = sum(dat$Size)
  }
  dat$N = 100*dat$Sum/gsize
  dat$N2 = 100*c(0, dat$Sum[-nrow(dat)]/gsize)
  return(dat)
}

get_dummy <- function(dat=NULL, type) {
  x_max=max(dat$N)
  data.frame(Type = c(type), Group = c("dummy"), Size = c(0), Sum = c(0), N = c(x_max), N2 = c(x_max))
}

bind_blocks <- function(block, block_dummy, scaff, scaff_dummy, contig, contig_dummy) {
  
  blocks = data.frame()
  if (!is.null(block)) {
    blocks=rbind(blocks, block, block_dummy)
  }
  if (!is.null(scaff)) {
    blocks=rbind(blocks, scaff, scaff_dummy)
  }
  if (!is.null(contig)) {
    blocks=rbind(blocks, contig, contig_dummy)
  }
  return(blocks)
}

plot_block <- function(dat = NULL, stats) {
  # by phased block
  y_max=max(dat$Size)
  ggplot(data = dat, aes(x = dat[,5], y = dat[,3], fill = dat[,2], colour = dat[,2])) +
    geom_rect(xmin=dat[,6], xmax=dat[,5], ymin=0, ymax=dat[,3], alpha=0.7) +
    theme_bw() +
    theme(legend.text = element_text(size=11),
          legend.position = c(0.95,0.95),  # Modify this if the legend is covering your favorite circle
          legend.background = element_rect(size=0.1, linetype="solid", colour ="black"),
          legend.box.just = "right",
          legend.justification = c("right", "top"),
          axis.title=element_text(size=14,face="bold"),
          axis.text=element_text(size=12)) +
    scale_fill_brewer(palette = "Set1", name= names(dat)[2]) +
    scale_colour_brewer(palette = "Set1", name= names(dat)[2]) +
    scale_x_continuous(limits = c(0, 100)) +
    scale_y_continuous(limits = c(0, y_max), labels = fancy_scientific) +
    xlab(stats) + ylab("Size (bp)") +
    geom_vline(xintercept = 50, show.legend = FALSE, linetype="dashed", color="black")
}

block_n <- function(block=NULL, scaff=NULL, contig=NULL, out, gsize = 0, w = 6, h = 5, pdf=FALSE) {
  
  outformat="png"
  if (pdf) {
    outformat="pdf"
  }
  
  # Read file
  if (!is.null(block)) {
    block = attach_n(dat = block, gsize = gsize)
    block_dummy = get_dummy(dat = block, type = "block")
  }
  
  if (!is.null(scaff)) {
    scaff = attach_n(dat = scaff, gsize = gsize)
    scaff_dummy = get_dummy(dat = scaff, type = "scaffold")
  }
  
  if (!is.null(contig)) {
    contig = attach_n(dat = contig, gsize = gsize)
    contig_dummy = get_dummy(dat = contig, type = "contig")
  }
  
  stats = "NG"
  if (gsize == 0) {
    stats = "N"
  }

  # Plot phase blocks filled by haplotypes
  plot_block(block, stats)
  save_plot(out, "block", stats, outformat, h = h, w = w)
  
  dat = bind_blocks(block, block_dummy, scaff, scaff_dummy, contig, contig_dummy)
  y_max=max(dat$Size)
  
  ggplot(data = dat, aes(x = N2, y = Size, colour = Type)) +
    geom_step() +
    theme_bw() +
    theme(legend.text = element_text(size=11),
          legend.position = c(0.95,0.95),  # Modify this if the legend is covering your favorite circle
          legend.background = element_rect(size=0.1, linetype="solid", colour ="black"),
          legend.box.just = "right",
          legend.justification = c("right", "top"),
          axis.title=element_text(size=14,face="bold"),
          axis.text=element_text(size=12)) +
    scale_fill_brewer(palette = "Set1", name = "Type") +
    scale_colour_brewer(palette = "Set1", name= "Type") +
    scale_x_continuous(limits = c(0, 100)) +
    scale_y_continuous(limits = c(0, y_max), labels = fancy_scientific) +
    xlab(stats) + ylab("Size (bp)") +
    geom_vline(xintercept = 50, show.legend = FALSE, linetype="dashed", color="black")
  
  save_plot(out, "continuity", stats, outformat, h = h, w = w)
}

block_n(block = args$block, scaff = args$scaff, contig = args$contig, out = args$out, gsize = args$gsize, w = args$xdim, h = args$ydim, pdf = args$pdf)

