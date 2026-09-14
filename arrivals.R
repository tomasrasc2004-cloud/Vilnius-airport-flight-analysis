library(lmtest)
library(sandwich)
library(segmented)
library(nlme)
library(stats)

#Initial scatterplot visualisation and creation of initial model
a <- read.table("", header = T)
x <- a[,1]
y <- a[,2]
plot(x,y)
mo <- lm(y~x)
summary(mo)
plot(mo, 1)
plot(x,y)
abline(mo, col='red')

#Removal of 347 value because of contradictions in scheduled arrival time between different sources and creation of another model and visualisation
x <- x[-347]
y <- y[-347]
mo1 <- lm(y~x)
plot(x,y)
abline(mo1, col='red')

#Creation of segmented model at x=0 and visualisation 
mos <- segmented(mo1, seg.Z = ~x, psi = 0)
summary(mos)
plot(mos, ylim=c(-600,150), xlab='Departure difference', ylab='Arrival difference')
points(x,y)

#Residuals vs Fitted plot
plot(fitted(mos),resid(mos))

#Setting the model's breaking point at the estimated one
vc <- vcovHC(mos, type = "HC3")
ps <- mos$psi[1,"Est."]

mos$coefficients[4] <- ps

#HC3 robust standard errors, due to model's residuals heteroskedasticity
res <- coeftest(mos, vcov = vc)

#Ljung-Box test to check model's residuals autocorrelation. They're autocorrelated (p<0.05)
Box.test(resid(mos), lag = 10, type = "Ljung-Box")

#Checking residuals ARIMA model. It's an MA(3) model.
auto.arima(resid(mos))


# Creation of the GLS model
cutoff <- -2.789

x1    <- ifelse(x >= cutoff, 1, 0)
x2   <- x * x1

gls_model <- gls(
  y ~ x + x1 + x2,
  correlation = corARMA(p = 0, q = 3, form = ~ 1) 
)

#summary of the model. The MA(3) parameters are close to 0, the biggest one being ≈0.11.
#After cutoff point β0 is calculating adding intercept plus x1
#After cutoff point β1 is calculating adding x1 plus x2
summary(gls_model)

#Normalisation of new model's residuals. Normalised residuals in this case mean residuals, that were subtracted of it's autocorrelation.
e <- resid(gls_model, type = "normalized")

#Ljung-Box test is performed again. Residuals aren't autocorrelated (p>0.05)
Box.test(e, lag = 10, type = "Ljung-Box")

#Homoskedasticity test on squared new model's squared residuals. Residuals are homoskedastic (p>0.05)
bptest(e^2 ~ x + x1 + x2)
