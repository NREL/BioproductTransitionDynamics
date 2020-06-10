
require(data.table)
require(magrittr)
require(sensitivity)

require(ggplot2)

z.ranges <- fread("input-ranges.tsv")
z.ranges %>% dim

z.ranges %>% summary

z.design <- morris(
    NULL,
    factors = z.ranges$Variable,
    r = 500,
    design = list(
        type = "oat",
        levels = mapply(function(t, x0, x1) {
            if (t == "Integer")
                x1 - x0 + 1
            else if (t == "Boolean")
                2
            else
                5
        }, z.ranges$Type, z.ranges$`Sensitivity Minimum`, z.ranges$`Sensitivity Maximum`),
        grid.jump = 1
    )
)
z.design$X %>% dim

write.table(z.design$X, file = "design.tsv", row.names = FALSE, col.names = TRUE, sep = "\t", quote = FALSE)

z.inputs <- cbind(
    Run = 1:(dim(z.design$X)[1]),
    data.table(
        sweep(
            sweep(z.design$X, MARGIN = 2, z.ranges$`Sensitivity Maximum` - z.ranges$`Sensitivity Minimum`, `*`),
            MARGIN = 2,
            z.ranges$`Sensitivity Minimum`,
            `+`
        )
    )
)
z.inputs %>% summary

write.table(z.inputs, file="inputs.tsv", row.names = FALSE, col.names = TRUE, sep = "\t", quote = FALSE)

z.design <- fread("design.tsv")
z.design %>% dim

z.inputs <- fread("inputs.tsv")
z.inputs %>% dim

z.outputs <- fread("outputs.tsv")
z.outputs[Time == 2050] %>% summary

z.outputs.clean <- z.outputs[`Time` == 2050, .(Run, `Cumulative Production`)]
z.outputs.clean <- rbind(
    z.outputs.clean,
    data.table(Run = setdiff(1:5900, z.outputs[`Time` == 2050, `Run`]), `Cumulative Production` = 0)
)[order(Run)]$`Cumulative Production`
z.outputs.clean %>% summary

ind.rep <- function(i, p) {
# indices of the points of the ith trajectory in the DoE
  (1 : (p + 1)) + (i - 1) * (p + 1)
}

ee.oat <- function(X, y) {
  # compute the elementary effects for a OAT design
  p <- ncol(X)
  r <- nrow(X) / (p + 1)
  
#  if(is(y,"numeric")){
  if(inherits(y, "numeric")){
    one_i_vector <- function(i){
      j <- ind.rep(i, p)
      j1 <- j[1 : p]
      j2 <- j[2 : (p + 1)]
      # return((y[j2] - y[j1]) / rowSums(X[j2,] - X[j1,]))
      return(solve(X[j2,] - X[j1,], y[j2] - y[j1]))
    }
    ee <- vapply(1:r, one_i_vector, FUN.VALUE = numeric(p))
    ee <- t(ee)
    # "ee" is now a (r times p)-matrix.
#  } else if(is(y,"matrix")){
  } else if(inherits(y, "matrix")){
    one_i_matrix <- function(i){
      j <- ind.rep(i, p)
      j1 <- j[1 : p]
      j2 <- j[2 : (p + 1)]
      return(solve(X[j2,] - X[j1,], 
                   y[j2, , drop = FALSE] - y[j1, , drop = FALSE]))
    }
    ee <- vapply(1:r, one_i_matrix, 
                 FUN.VALUE = matrix(0, nrow = p, ncol = dim(y)[2]))
    # Special case handling for p == 1 and ncol(y) == 1 (in this case, "ee" is
    # a vector of length "r"):
    if(p == 1 && dim(y)[2] == 1){
      ee <- array(ee, dim = c(r, 1, 1))
    }
    # Transpose "ee" (an array of dimensions c(p, ncol(y), r)) to an array of
    # dimensions c(r, p, ncol(y)) (for better consistency with the standard 
    # case that "class(y) == "numeric""):
    ee <- aperm(ee, perm = c(3, 1, 2))
#  } else if(is(y,"array")){
  } else if(inherits(y, "array")){
    one_i_array <- function(i){
      j <- ind.rep(i, p)
      j1 <- j[1 : p]
      j2 <- j[2 : (p + 1)]
      ee_per_3rd_dim <- sapply(1:(dim(y)[3]), function(idx_3rd_dim){
        y_j2_matrix <- y[j2, , idx_3rd_dim]
        y_j1_matrix <- y[j1, , idx_3rd_dim]
        # Here, the result of "solve(...)" is a (p times dim(y)[2])-matrix or
        # a vector of length dim(y)[2] (if p == 1):
        solve(X[j2,] - X[j1,], y_j2_matrix - y_j1_matrix)
      }, simplify = "array")
      if(dim(y)[2] == 1){
        # Correction needed if dim(y)[2] == 1, so "y_j2_matrix" and
        # "y_j1_matrix" have been dropped to matrices (or even vectors, if also
        # p == 1):
        ee_per_3rd_dim <- array(ee_per_3rd_dim, 
                                dim = c(p, dim(y)[2], dim(y)[3]))
      } else if(p == 1){
        # Correction needed if p == 1 (and dim(y)[2] > 1), so "y_j2_matrix" and
        # "y_j1_matrix" have been dropped to matrices:
        ee_per_3rd_dim <- array(ee_per_3rd_dim, 
                                dim = c(1, dim(y)[2], dim(y)[3]))
      }
      # "ee_per_3rd_dim" is now an array of dimensions 
      # c(p, dim(y)[2], dim(y)[3]). Assign the corresponding names for the 
      # third dimension:
      if(is.null(dimnames(ee_per_3rd_dim))){
        dimnames(ee_per_3rd_dim) <- dimnames(y)
      } else{
        dimnames(ee_per_3rd_dim)[[3]] <- dimnames(y)[[3]]
      }
      return(ee_per_3rd_dim)
    }
    ee <- sapply(1:r, one_i_array, simplify = "array")
    # Special case handling if "ee" has been dropped to a vector:
#    if(is(ee,"numeric")){
    if (inherits(ee, "numeric")){
      ee <- array(ee, dim = c(p, dim(y)[2], dim(y)[3], r))
      dimnames(ee) <- list(NULL, dimnames(y)[[2]], dimnames(y)[[3]], NULL)
    }
    # "ee" is an array of dimensions c(p, dim(y)[2], dim(y)[3], r), so it is
    # transposed to an array of dimensions c(r, p, dim(y)[2], dim(y)[3]):
    ee <- aperm(ee, perm = c(4, 1, 2, 3))
  }
  return(ee)
}

z.ee <- ee.oat(z.design, z.outputs.clean)
z.ee %>% dim

z.mu <- apply(z.ee, 2, mean)
z.mustar <- apply(z.ee, 2, function(x) mean(abs(x)))
z.sigma <- apply(z.ee, 2, sd)
z.result <- data.table(
    variable = names(z.mu),
    mu       = z.mu       ,
    mustar   = z.mustar   ,
    sigma    = z.sigma
)

z.result[, `:=`(`mu rank` = frank(-mu), `mustar rank` = frank(-mustar), `sigma rank` = frank(-sigma))]
z.result[order(-mustar)]

ggplot(z.result, aes(x = mu, y = sigma, color = mustar, label = variable)) +
    geom_point() +
    geom_text(size = 2, hjust = 0, vjust = 0)
