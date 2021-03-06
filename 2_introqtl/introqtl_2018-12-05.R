# Intro to QTL mapping with R/qtl
# Live coding at ICRISAT workshop 2018-12-05
#
# largely following http://rqtl.org/tutorials/rqtltour2.pdf
# latest version of this script at https://bit.ly/introqtl2018

# load R/qtl
library(qtl)

# import some QTL mapping data
# example data file at http://rqtl.org/sug.csv
sug <- read.cross("csv", "http://rqtl.org", "sug.csv",
                  genotypes=c("CC", "CB", "BB"), 
                  alleles=c("C", "B"))

# summary of data
summary(sug)
plot(sug)
plotMissing(sug) # black pixels = missing genotypes
plotMap(sug)

nind(sug)
nmar(sug)
totmar(sug)

# histograms of phenotypes
plotPheno(sug, pheno.col=1)
plotPheno(sug, pheno.col="bw")

# first step in QTL analysis: calculate genotype probabilities
sug <- calc.genoprob(sug, step=1)

# 2nd step in QTL analysis: do the LOD score calculations by interval mapping
out.em <- scanone(sug)
plot(out.em)
phenames(sug)

# permutation test
operm <- scanone(sug, n.perm=1000)
operm
plot(operm)

# 5% and 10% significance thresholds
summary(operm) 
# 20% significance threshold
summary(operm, alpha=0.2)

# significant peaks in QTL results
summary(out.em, perms=operm, alpha=0.5, pvalues=TRUE)

# genome scan with multiple traits
phenames(sug)
out.all <- scanone(sug, pheno.col=1:4)
head(out.all)
dim(out.all)

# plot the LOD curves
plot(out.all, lodcolumn=1:3)
plot(out.all, lodcolumn=4, col="green", add=TRUE)
legend("topleft", lwd=2, 
       col=c("black", "blue", "red", "green"),
       phenames(sug)[1:4])

# permutation test for all 4 traits
operm.all <- scanone(sug, pheno.col = 1:4, n.perm=1000, n.cluster=8)
summary(operm.all)

summary(out.all, perms=operm.all, alpha=0.2,
        format="tabByChr", pvalues=TRUE)

# lod support intervals
lodint(out.all, lodcolumn=1, chr=7)
lodint(out.all, lodcolumn=1, chr=7, drop=2)
lodint(out.all, lodcolumn=1, chr=7, drop=1)
lodint(out.all, lodcolumn=1, chr=15)

# Haley-Knott regression
out.all.hk <- scanone(sug, pheno.col=1:4,
                      method="hk")
# permutation test of that
operm.all.hk <- scanone(sug, pheno.col=1:4,
                        method="hk", 
                        n.perm=1000,
                        n.cluster=8)
plot(out.all, out.all.hk, lodcolumn=1, 
     lty=1:2, col=c("slateblue", "violetred"))

# imputation method
sug <- sim.geno(sug, step=1, n.draws=32)
out.all.imp <- scanone(sug, method="imp",
                       pheno.col=1:4)
plot(out.all, out.all.hk, out.all.imp)


# [lunch]

# install the R/qtlcharts package
install.packages("qtlcharts")

# load the R/qtlcharts package
library(qtlcharts)

# interactive plot of genetic map
iplotMap(sug)

# interactive LOD curve plot
iplotScanone(out.all)
iplotScanone(out.all, sug, chr=c(2,7,11,15))
iplotScanone(out.all, sug, chr=c(2,7,11,15), 
             lodcolumn=2, pheno.col=2)
iplotScanone(out.all, sug, chr=c(2,7,11,15),pxgtype="raw")

# show marker names
plotMap(sug, show.marker.names=TRUE)

# non-parametric genome scan for the bp trait
out.np <- scanone(sug, model="np")
plot(out.np)
plot(out.em, col="Orchid", lty=2, add=TRUE)

# create a binary trait as bp > median
bp <- pull.pheno(sug, pheno.col="bp")
bp_bin <- (bp > median(bp, na.rm=TRUE))*1
out.bin <- scanone(sug, pheno.col=bp_bin,
                   model="binary")
plot(out.bin, col="green", lty=3, add=TRUE)

# qtl scan with covariates
bw <- pull.pheno(sug, pheno.col="bw")
out.hw.bwadd <- scanone(sug, pheno.col="heart_wt",
                        addcovar=bw)
plot(out.hw.bwadd)

out.hw.bwint <- scanone(sug, pheno.col="heart_wt",
                        addcovar=bw, intcovar=bw)
plot(out.hw.bwint)

out.hw.bwi <- out.hw.bwint - out.hw.bwadd
plot(out.hw.bwi)

# [killed RStudio; re-load everything]
library(qtl)
sug <- read.cross("csv", "http://rqtl.org", "sug.csv",
                  genotypes=c("CC", "CB", "BB"), 
                  alleles=c("C", "B"))

# re-run calc.genoprob, using step=2.5
sug <- calc.genoprob(sug, step=2.5)

# two-dimensional scan 
out2 <- scantwo(sug, method="hk", verbose=FALSE)
plot(out2)

# show fv1 in lower triangle
plot(out2, lower="fv1")

# permutation test with 2d scan
##  operm2 <- scantwo(sug, method="hk", n.perm=1000)  # often has problems
## operm2 <- scantwopermhk(sug, n.perm=1000)          # better but really slow

# load previously-calculated permutation results
load(url("http://rqtl.org/various.RData"))

# significance thresholds from 2d scan
summary(operm2)

# what pairs of chromosomes are interesting?
summary(out2, perms=operm2, alpha=0.2, pvalues=TRUE)

# in case R crashes, it can be useful to have saved your work
save.image()

# multiple qtl model building
max(out2) # best overall model

# create a qtl object with chr 7 locus
qtl_c7 <- makeqtl(sug, chr=7, pos=46.7, what="prob")
# scan for an additional QTL
out_c7plus1 <- addqtl(sug, qtl=qtl_c7, method="hk")

plot(out_c7plus1)
out.hk <- scanone(sug, method="hk")
plot(out.hk, col="green", add=TRUE)

# do the same with chr 15 at 14 cM
qtl_c15 <- makeqtl(sug, 15, 14, what="prob")
out_c15plus1 <- addqtl(sug, qtl=qtl_c15)
par(mfrow=c(1,1)) # clear the multi-panel plot
plot(out_c15plus1, out.hk, col=c("black", "green"))

# create QTL model with both chr 7 and chr 15
qtl_7n15 <- makeqtl(sug, c(7,15), c(46.7, 14), what="prob")
out_7n15plus1 <- addqtl(sug, qtl=qtl_7n15)
plot(out_7n15plus1)

# fit two qtl model and look at QTL effects
out.fq <- fitqtl(sug, qtl=qtl_7n15, method="hk", get.ests=TRUE)
summary(out.fq)

# look at the picture again
library(qtlcharts)
iplotScanone(out.hk, sug, chr=c(7,15))

# look for interactions
out.int <- addint(sug, qtl=qtl_7n15, method="hk")
summary(out.int)

# stepwiseqtl to automatically build multiple-qtl models
out.sq1 <- stepwiseqtl(sug, method="hk", penalties=3.5,
                       additive.only=TRUE)

# calculate the penalties
pen <- calc.penalties(operm2)
pen

# stepwise analysis, including interactions
out.sq2 <- stepwiseqtl(sug, method="hk", penalties=pen)

# lod support interval
lodint(out.sq2, qtl=1)
lodint(out.sq2, qtl=2)
