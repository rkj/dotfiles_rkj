function cdtoday
    set -l dir (date +%Y-%m-%d)$argv
    mkdir -p $dir
    cd $dir
end
