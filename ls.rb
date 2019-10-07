#! /user/bin/env ruby
#
# ls : 引数なしの場合、現在のディレクトリーの状態を返す
#    : 引数ありの場合、そのディレクトリーの状態を返す
#
# フィルターオプション
# -a 全てのファイルやディレクトリを表示
# -R 再帰的にディレクトリの中身も表示する
#
# データの加工オプション
# -l ファイルの詳細を表示
# --full-time タイムスタンプの詳細を表示
# -h(-lh) ファイルサイズの形式をわかりやすい単位で表示する
# -k(-lk) キロバイト単位で表示
# -i(-li) ノード番号も含んだ情報を表示する
# -F 名前の後ろにファイル識別子をつける
#
# ソートするオプション
# -r(-lr) 逆順に表示する
# -t(-tl) 更新時間順に表示する
# -l(-lS) ファイルサイズ順に表示する
# -X(-lX) 拡張子のアルファベット順に表示する
#
# 出力を変えるオプション
# -1 1行に1件表示する
# -m 情報をカンマ区切りで表示する
#
# +α
# -d ディレクトリ自体の情報を表示する
# -x 縦方向じゃなくて横方向に並べる
# -Q 情報をダブルクウォートで囲んで表示する
# --ignore=PATTERN PATTERNに一致する情報以外の情報を表示する

class FilterOption
	#attr_reader :entries, :options

	def initialize(entries, options)
		@entries = entries
		@options = options
	end

	def filter
		if @options.include?('-a')
			a_option
		else
			@entries.select{|e| e[0] != '.'}
		end
	end

	private 

	def a_option
		@entries
	end
end

class ProcessingOption
	#attr_reader :entries, :options, :target

	def initialize(entries, options, target)
		@entries = entries
		@options = options
		@target = target
	end

	def processing
		if @options.include?('-l')
			return l_option
		else
			@entries
		end
	end

	private 

	# 少しだけ実装
	def l_option
		entries = @entries.map{|entry| "#{File.size(entry)} #{entry}\n"}
=begin
	
rescue Exception => e
	
end
		entries = @entries.map{|entry|
			[{num_harding: true,
			owner: true,
			name_group: true,
			size_byte: true,
			time_stamp: true,
			name: entry}]
		}
=end
	end

end

class SortOption
	attr_reader :entries, :options, :target

	def initialize(entries, options, target)
		@entries = entries
		@options = options
		@target = target
	end

	def sort
		if @options.include?('-S')
			return large_s_option
		else
			@entries
		end
	end

	private 

	def large_s_option
		@entries = @entries.sort{|a, b| 
			File.size(File.path("#{@target}/#{a}")) <=> File.size(File.path("#{@target}/#{b}"))}
	end
end

class OutputOption
	attr_reader :entries, :options

	def initialize(entries, options)
		@entries = entries
		@options = options
	end

	def output
		if @options.include?('-1')
			return one_option
		else
			@entries.join(' ')
		end
	end

	private 

	def one_option
		@entries = @entries.map{|entry| 
			if entry.include?("\n")
				entry
			else
				"#{entry}\n"
			end
		}
	end

end


# lsで表示するディレクトリ target
target = Dir.pwd
ARGV.each do |f|
	target = f if f[0] != '-'
end

# 与えられたオプション options
options = ARGV.select{|e| e[0] == '-'}

# 表示するファイルまたはディレクトリの集合 entries
entries = Dir::entries(target)

# templete methodなどで処理を固定したほうが良い
# filter
filter_option = FilterOption.new(entries,options)
entries = filter_option.filter

# sort
sort_option = SortOption.new(entries,options,target)
entries = sort_option.sort

# processing
processing_option = ProcessingOption.new(entries,options,target)
entries = processing_option.processing

# output
output_option = OutputOption.new(entries,options)
entries = output_option.output

puts entries