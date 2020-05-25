
require(data.table)
require(magrittr)
require(sensitivity)

z.ranges <- fread("input-ranges.tsv")
z.ranges %>% dim

z.design <- morris(
    NULL,
    factors = z.ranges$Variable,
    r = 100,
    design = list(
        type = "oat",
        levels = mapply(function(t, x0, x1) {
            if (t == "Integer")
                x1 - x0 + 1
            else if (t == "Boolean")
                2
            else
                5
        }, z.ranges$Type, z.ranges$Minimum, z.ranges$Maximum),
        grid.jump = 1
    )
)
z.design$X %>% dim

write.table(z.design$X, file = "design.tsv", row.names = FALSE, col.names = TRUE, sep = "\t", quote = FALSE)

z.inputs <- cbind(
    Run = 1:(dim(z.design$X)[1]),
    data.table(
        sweep(
            sweep(z.design$X, MARGIN = 2, z.ranges$Maximum - z.ranges$Minimum, `*`),
            MARGIN = 2,
            z.ranges$Minimum,
            `+`
        )
    )
)
z.inputs %>% summary

write.table(z.inputs, file="inputs.tsv", row.names = FALSE, col.names = TRUE, sep = "\t", quote = FALSE)

?morris

fread("outputs.tsv")[Time == 2020] %>% summary


