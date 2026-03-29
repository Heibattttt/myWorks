newdat <- read.csv('kc_house_data.csv')
newdat
colnames(newdat)

describe(newdat)
summary(newdat)
################################################################################
# Step 1: Histograms
################################################################################
numeric_cols <- c("price","bedrooms","bathrooms","sqft_living","sqft_lot",
                  "floors","waterfront","view","condition","grade",
                  "sqft_above","sqft_basement","yr_built","yr_renovated",
                  "lat","long","sqft_living15","sqft_lot15")

par(mfrow=c(3,6))  # 18 numeric variables
for (col in numeric_cols) {
  hist(newdat[[col]], main=col, xlab=col, col="skyblue", border="white")
}
par(mfrow=c(1,1))

pdf("histograms.pdf", width=14, height=8)
par(mfrow=c(3,6))  # 3 rows, 6 columns
for (col in numeric_cols) {
  hist(newdat[[col]], main=col, xlab=col, col="skyblue", border="white")
}
par(mfrow=c(1,1))
dev.off()
# Variables that make sense to log
loggable_cols <- c("price","sqft_living","sqft_lot","sqft_above",
                   "sqft_basement","sqft_living15","sqft_lot15")

for (col in loggable_cols) {
  newdat[[paste0(col, "_log")]] <- log1p(newdat[[col]])
}

correlations <- cor(newdat[numeric_cols], use = "complete.obs")

# View the correlation of all variables with price
cor_with_price <- correlations["price", ]
print(cor_with_price)

# Sort correlations by strength (descending)
sort(cor_with_price, decreasing = TRUE)
barplot(cor_with_price,
        main="Correlation of Each Variable with Price",
        ylab="Correlation Coefficient",
        xlab="Variables",
        col="skyblue",
        las=2,  # rotate x-axis labels
        cex.names=0.8)  # smaller font for labels

cor_matrix <- cor(newdat[numeric_cols], use="complete.obs")
cor_values <- cor_matrix[lower.tri(cor_matrix)]
hist(cor_values, 
     breaks=20, 
     main="Histogram of Pairwise Correlations",
     xlab="Correlation Coefficient",
     col="skyblue", border="white")

################################################################################
# Step 2: Data preparation
################################################################################
newdat$price_log <- log(newdat$price)

# Scale predictors and convert to numeric vectors
newdat$sqft_living_scaled   <- as.vector(scale(newdat$sqft_living))
newdat$grade_scaled         <- as.vector(scale(newdat$grade))
newdat$sqft_above_scaled    <- as.vector(scale(newdat$sqft_above))
newdat$sqft_living15_scaled <- as.vector(scale(newdat$sqft_living15))
newdat$bathrooms_scaled     <- as.vector(scale(newdat$bathrooms))
################################################################################
# Step 3: Model 1 (Simple: sqft_living + grade)
################################################################################
data_jags_1 <- list(
  y  = newdat$price_log,
  x1 = newdat$sqft_living_scaled,
  x2 = newdat$grade_scaled,
  N  = nrow(newdat)
)

# Remove rows with missing values in the relevant columns
dat1 <- na.omit(newdat[, c("price_log", "sqft_living_scaled", "grade_scaled")])

# Prepare JAGS list
data_jags_1 <- list(
  y  = dat1$price_log,
  x1 = dat1$sqft_living_scaled,
  x2 = dat1$grade_scaled,
  N  = nrow(dat1)
)


model_string_1 <- "
model {
  for (i in 1:N) {
    y[i] ~ dnorm(mu[i], tau)
    mu[i] <- beta0 + beta1*x1[i] + beta2*x2[i]
  }
  beta0 ~ dnorm(0, 0.0001)
  beta1 ~ dnorm(0, 0.0001)
  beta2 ~ dnorm(0, 0.0001)
  tau ~ dgamma(0.001, 0.001)
  sigma <- 1 / sqrt(tau)
}
"

jags_1 <- jags.model(textConnection(model_string_1), data = data_jags_1, n.chains = 3, n.adapt = 1000)
update(jags_1, 1000)

samples_1 <- coda.samples(jags_1,
                          variable.names = c("beta0","beta1","beta2","sigma"),
                          n.iter = 5000)

posterior_matrix_1 <- as.matrix(samples_1)
posterior_summary_1 <- data.frame(
  Parameter = colnames(posterior_matrix_1),
  Mean = apply(posterior_matrix_1, 2, mean),
  SD   = apply(posterior_matrix_1, 2, sd),
  `2.5%` = apply(posterior_matrix_1, 2, quantile, 0.025),
  `97.5%` = apply(posterior_matrix_1, 2, quantile, 0.975)
)
print(posterior_summary_1, digits=5)

Posterior predictive check (LOG scale)
set.seed(123)
post_idx_1 <- sample(1:nrow(posterior_matrix_1), 200)
y_rep_1_log <- matrix(NA, nrow=nrow(dat1), ncol=length(post_idx_1))
for (k in seq_along(post_idx_1)) {
  theta <- posterior_matrix_1[post_idx_1[k],]
  mu_k <- theta["beta0"] + theta["beta1"]*dat1$sqft_living_scaled + theta["beta2"]*dat1$grade_scaled
  # simulate on log scale (no exp)
  y_rep_1_log[,k] <- rnorm(nrow(dat1), mean = mu_k, sd = theta["sigma"])
}

par(mfrow=c(1,2))
hist(dat1$price_log, main="Observed price_log (Model 1 data)", col="lightblue", xlab="price_log")
hist(as.vector(y_rep_1_log), main="Posterior Predictive (Model 1) on log scale", col="lightgreen", xlab="price_log")
par(mfrow=c(1,1))

# Example for Model 1 (log scale)
################################################################################
# Posterior Predictive Check: Overlay plots
################################################################################

### --- Model 1 --- ###
obs1 <- dat1$price_log
sim1 <- as.vector(y_rep_1_log)

# Density overlay
plot(density(obs1), col="blue", lwd=2, main="PPC: Observed vs Replicated (Model 1)",
     xlab="price_log", ylim=c(0, max(density(obs1)$y, density(sim1)$y)))
lines(density(sim1), col="red", lwd=2, lty=2)
legend("topright", legend=c("Observed","Replicated"),
       col=c("blue","red"), lwd=2, lty=c(1,2))

# Transparent histogram overlay
hist(obs1, breaks=50, freq=FALSE, col=rgb(0,0,1,0.4), border="white",
     main="PPC Histogram: Observed vs Replicated (Model 1)", xlab="price_log")
hist(sim1, breaks=50, freq=FALSE, col=rgb(1,0,0,0.4), border="white", add=TRUE)
legend("topright", legend=c("Observed","Replicated"),
       fill=c(rgb(0,0,1,0.4), rgb(1,0,0,0.4)))

### --- Model 2 --- ###
obs2 <- dat2$price_log
sim2 <- as.vector(y_rep_2_log)

# Density overlay
plot(density(obs2), col="blue", lwd=2, main="PPC: Observed vs Replicated (Model 2)",
     xlab="price_log", ylim=c(0, max(density(obs2)$y, density(sim2)$y)))
lines(density(sim2), col="red", lwd=2, lty=2)
legend("topright", legend=c("Observed","Replicated"),
       col=c("blue","red"), lwd=2, lty=c(1,2))

# Transparent histogram overlay
hist(obs2, breaks=50, freq=FALSE, col=rgb(0,0,1,0.4), border="white",
     main="PPC Histogram: Observed vs Replicated (Model 2)", xlab="price_log")
hist(sim2, breaks=50, freq=FALSE, col=rgb(1,0,0,0.4), border="white", add=TRUE)
legend("topright", legend=c("Observed","Replicated"),
       fill=c(rgb(0,0,1,0.4), rgb(1,0,0,0.4)))


# Posterior predictive check
set.seed(123)
post_idx_1 <- sample(1:nrow(posterior_matrix_1), 200)
y_rep_1 <- matrix(NA, nrow=nrow(newdat), ncol=length(post_idx_1))
for (k in seq_along(post_idx_1)) {
  theta <- posterior_matrix_1[post_idx_1[k],]
  mu_k <- theta["beta0"] + theta["beta1"]*newdat$sqft_living_scaled + theta["beta2"]*newdat$grade_scaled
  y_rep_1[,k] <- exp(rnorm(nrow(newdat), mean=mu_k, sd=theta["sigma"]))
}

par(mfrow=c(1,2))
hist(newdat$price, main="Observed Price", col="lightblue", xlab="Price")
hist(as.vector(y_rep_1), main="Posterior Predictive (Model 1)", col="lightgreen", xlab="Price")
par(mfrow=c(1,1))




################################################################################
# Step 4: Model 2 (Extended: sqft_living + grade + sqft_above + sqft_living15 + bathrooms)
################################################################################
data_jags_2 <- list(
  y  = newdat$price_log,
  x1 = newdat$sqft_living_scaled,
  x2 = newdat$grade_scaled,
  x3 = newdat$sqft_above_scaled,
  x4 = newdat$sqft_living15_scaled,
  x5 = newdat$bathrooms_scaled,
  N  = nrow(newdat)
)

model_string_2 <- "
model {
  for (i in 1:N) {
    y[i] ~ dnorm(mu[i], tau)
    mu[i] <- beta0 + beta1*x1[i] + beta2*x2[i] + beta3*x3[i] + beta4*x4[i] + beta5*x5[i]
  }
  beta0 ~ dnorm(0, 0.0001)
  beta1 ~ dnorm(0, 0.0001)
  beta2 ~ dnorm(0, 0.0001)
  beta3 ~ dnorm(0, 0.0001)
  beta4 ~ dnorm(0, 0.0001)
  beta5 ~ dnorm(0, 0.0001)
  tau ~ dgamma(0.001, 0.001)
  sigma <- 1 / sqrt(tau)
}
"

jags_2 <- jags.model(textConnection(model_string_2), data = data_jags_2, n.chains = 3, n.adapt = 1000)
update(jags_2, 1000)

samples_2 <- coda.samples(jags_2,
                          variable.names = c("beta0","beta1","beta2","beta3","beta4","beta5","sigma"),
                          n.iter = 5000)

posterior_matrix_2 <- as.matrix(samples_2)
posterior_summary_2 <- data.frame(
  Parameter = colnames(posterior_matrix_2),
  Mean = apply(posterior_matrix_2, 2, mean),
  SD   = apply(posterior_matrix_2, 2, sd),
  `2.5%` = apply(posterior_matrix_2, 2, quantile, 0.025),
  `97.5%` = apply(posterior_matrix_2, 2, quantile, 0.975)
)
print(posterior_summary_2, digits=5)

# Diagnostics
plot(samples_2)
gelman.diag(samples_2)
effectiveSize(samples_2)

# Posterior predictive check
set.seed(123)
post_idx_2 <- sample(1:nrow(posterior_matrix_2), 200)
y_rep_2 <- matrix(NA, nrow=nrow(newdat), ncol=length(post_idx_2))
for (k in seq_along(post_idx_2)) {
  theta <- posterior_matrix_2[post_idx_2[k],]
  mu_k <- theta["beta0"] + theta["beta1"]*newdat$sqft_living_scaled +
    theta["beta2"]*newdat$grade_scaled + theta["beta3"]*newdat$sqft_above_scaled +
    theta["beta4"]*newdat$sqft_living15_scaled + theta["beta5"]*newdat$bathrooms_scaled
  y_rep_2[,k] <- exp(rnorm(nrow(newdat), mean=mu_k, sd=theta["sigma"]))
}

par(mfrow=c(1,2))
hist(newdat$price, main="Observed Price", col="lightblue", xlab="Price")
hist(as.vector(y_rep_2), main="Posterior Predictive (Model 2)", col="lightgreen", xlab="Price")
par(mfrow=c(1,1))

################################################################################
# Step 5: Model comparison with DIC
################################################################################

#### --- Frequentist OLS on log scale for fair comparison --- ####

# Model 1: 2 predictors (sqft_living + grade)
ols_two_log <- lm(price_log ~ scale(sqft_living) + scale(grade), data = newdat)
summary(ols_two_log)

# Model 2: 5 predictors (sqft_living + grade + sqft_above + sqft_living15 + bathrooms)
ols_full_log <- lm(price_log ~ scale(sqft_living) + scale(grade) +
                     scale(sqft_above) + scale(sqft_living15) + scale(bathrooms),
                   data = newdat)
summary(ols_full_log)




dic_1 <- dic.samples(jags_1, n.iter=5000, type="pD")
dic_2 <- dic.samples(jags_2, n.iter=5000, type="pD")

dic_table <- data.frame(
  Model = c("Model 1 (2 predictors)","Model 2 (5 predictors)"),
  MeanDeviance = c(mean(dic_1$deviance), mean(dic_2$deviance)),
  pD = c(mean(dic_1$penalty), mean(dic_2$penalty)),
  DIC = c(mean(dic_1$deviance)+mean(dic_1$penalty),
          mean(dic_2$deviance)+mean(dic_2$penalty))
)
print(dic_table, digits=4)


set.seed(123)
post_idx_2 <- sample(1:nrow(posterior_matrix_2), 200)
y_rep_2_log <- matrix(NA, nrow=nrow(dat2), ncol=length(post_idx_2))
for (k in seq_along(post_idx_2)) {
  theta <- posterior_matrix_2[post_idx_2[k],]
  mu_k <- theta["beta0"] + theta["beta1"]*dat2$sqft_living_scaled +
    theta["beta2"]*dat2$grade_scaled + theta["beta3"]*dat2$sqft_above_scaled +
    theta["beta4"]*dat2$sqft_living15_scaled + theta["beta5"]*dat2$bathrooms_scaled
  # simulate on log scale (no exp)
  y_rep_2_log[,k] <- rnorm(nrow(dat2), mean = mu_k, sd = theta["sigma"])
}

par(mfrow=c(1,2))
hist(dat2$price_log, main="Observed price_log (Model 2 data)", col="lightblue", xlab="price_log")
hist(as.vector(y_rep_2_log), main="Posterior Predictive (Model 2) on log scale", col="lightgreen", xlab="price_log")
par(mfrow=c(1,1))