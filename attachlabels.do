
// attachlabels.do
///
foreach v of var * {
        label var `v' "`l`v''"
}
///

