#! /user/bin/env ruby
#
# ls : 引数なしの場合、現在のディレクトリーの状態を返す
#    : 引数ありの場合、そのディレクトリーの状態を返す
#
### フィルターオプション
# -a 全てのファイルやディレクトリを表示
# -R 再帰的にディレクトリの中身も表示する
#
### データの加工オプション
# -l ファイルの詳細を表示
# --full-time タイムスタンプの詳細を表示(未実装)
# -h(-lh) ファイルサイズの形式をわかりやすい単位で表示する
# -k(-lk) キロバイト単位で表示
# -i(-li) ノード番号も含んだ情報を表示する
# -F 名前の後ろにファイル識別子をつける(未実装)
#
### ソートするオプション
# -r(-lr) 逆順に表示する
# -t(-tl) 更新時間順に表示する
# -l(-lS) ファイルサイズ順に表示する
# -X(-lX) 拡張子のアルファベット順に表示する(未実装)
#
### 出力を変えるオプション
# -1 1行に1件表示する
# -m 情報をカンマ区切りで表示する
#
### +α
# -d ディレクトリ自体の情報を表示する
# -x 縦方向じゃなくて横方向に並べる
# -Q 情報をダブルクウォートで囲んで表示する
# --ignore=PATTERN PATTERNに一致する情報以外の情報を表示する

class FilterOption
	def initialize(entries, options)
		@entries = entries
		@options = options
	end

	def filter
		if @options.include?('-a')
			a_option
		else
			@entries.select{|entry| entry[:name][0] != '.'}
		end
	end

	private 

	def a_option
		@entries
	end
end

class ProcessingOption
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

	# permission以外実装
	def l_option
		entries = @entries.map{|entry|
			stat = File::Stat.new(entry[:name])
			entry[:file_type] = File.ftype(entry[:name]) #ftype(filename)
			entry[:permission] = nil
			entry[:num_hardlink] = stat.nlink #File::Stat(path).nlink
			entry[:owner_name] = stat.uid #File::Stat(path).uid
			entry[:group_name] = stat.gid #File::Stat(path).gid
			entry[:byte_size] = stat.size #FileTest.size | File::Stat(path).size
			entry[:time_stamp] = stat.atime #File.atime(filename) | ctime | utime | mtime
			entry
		}
	end

	def h_option
		entries = @entries.map{|entry|
			if entry[:byte_size].nil?
				entry[:byte_size] = File::Stat.new(entry[:name]).size 
			end

			if entry[:byte_size] > 10**6
				entry[:byte_size] = "#{entry[:byte_size] / 1000000}G"
			elsif entry[:byte_size] > 10**3
				entry[:byte_size] = "#{entry[:byte_size] / 1000}k"
			end
				
			entry
		}
	end

	def i_option
		entries = @entries.map{|entry| 
			entry[:num_node] = File::Stat.new(entry).ino
			entry
		}
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
		@entries = large_s_option if @options.include?('-S')
		@entries =  t_option if @options.include?('-t')
		@entries = r_option if @options.include?('-r')
		@entries
	end

	private 

	def large_s_option
		@entries = @entries.sort{|a, b| a[:byte_size] <=> b[:byte_size]}
	end

	def t_option
		@entries = @entries.sort{|a, b| a[:time_stamp] <=> b[:time_stamp]}
	end

	def r_option

		entries = @entries.reverse
	end
end

class MakeOutput
	def initialize(entries, options)
		@entries = entries
		@options = options
	end
end

class OutputOption
	def initialize(entries, options)
		@entries = entries
		@options = options
	end

	def output
		if @options.include?('-1' || '-l')
			return one_option
		else
			@entries
		end
	end

	private 

	def one_option
		entries = @entries.map{|entry| entry[:output] += "\n"}
	end

	def m_option
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
entries = Dir::entries(target).map{|entry| {name: entry}} 

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