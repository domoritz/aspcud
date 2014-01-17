#!/bin/bash

location="$(readlink -f "$(dirname $0)")"
encoding="$location"/../scripts/encodings/misc2012.lp
#encoding="$location"/../scripts/encodings/specification.lp

clasp=clasp
unclasp=unclasp
gringo=gringo-4
cudf="$location"/../build/debug/bin/cudf2lp

for x in "$location"/enumerate-all/*.cudf; do
    echo "================== $(basename $x) ================="
    "$cudf" < "$x" 2>/dev/null | $gringo - "$encoding" 2>/dev/null | "$clasp" 0 --outf=1 -V0 -q0,0 | grep -v "A" |\
    while read line; do
        if [[ -n "$line" ]]; then
            echo "$line" | tr " " "\n" | sort | tr -d "\n"
            echo
        fi
    done | sort | diff - "$(dirname "$x")/$(basename "$x" .cudf)".sol && echo "passed" || echo "FAILED"
done

for x in "$location"/*/*.cudf.xz; do
    crit=$(echo "$(basename "$(dirname "$x")")" | tr "PMLRC" '\+\-(),')
    echo "================== $(basename $x) with $crit ================="
    xzcat "$x" > problem.cudf
    #TODO: at some point add back unclasp ...
    for solver in "$clasp"; do
        for encoding in "$location/../scripts/encodings/misc2012.lp" "$location/../scripts/encodings/specification.lp"; do
            #echo ../build/debug/bin/aspcud -e "$encoding" -s "$solver" -g "$gringo" "${extra[@]}" problem.cudf solution.cudf "\"$crit\""
            ../build/debug/bin/aspcud -e "$encoding" -s "$solver" -g "$gringo" "${extra[@]}" problem.cudf solution.cudf "$crit" > /dev/null
            cudf-sol-check -cudf problem.cudf -sol solution.cudf -crit "$crit" > solution.opt
            diff "${x%.cudf.xz}.opt" solution.opt && echo "passed" || echo "FAILED ($encoding/$solver)"
            rm -f solution.cudf solution.opt
        done
    done
    rm -f problem.cudf
done
