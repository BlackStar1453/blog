#!/bin/bash
export CURRENT_YEAR=$(date +%Y)
export CURRENT_MONTH=$(date +%m)
export CURRENT_DATE=$(date +%d)
export CURRENT_HOUR=$(date +%H)
export CURRENT_MINUTE=$(date +%M)
export CURRENT_SECOND=$(date +%S)

my_dir="$(dirname "$0")"

# 生成 URL 友好的 slug
function generate_slug() {
    local title="$1"
    # 转换为小写，替换空格和特殊字符为连字符，移除多余的连字符
    echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-\|-$//g'
}

# template functions
function template() {
  template_path="$1"
  target_path="$2"
  target_dir="$(dirname $target_path)"
  # check target dir is exist, if not, create it
  if [ ! -d "$target_dir" ]; then
      mkdir -p $target_dir
  fi

  # check target file is exists
  if [ ! -f $target_path ]; then
      # echo "$target_path file exists"
      cat $template_path | ${my_dir}/mo.sh > $target_path
      # echo "$target_path created!"
  fi
}
