#! /user/bin/env ruby
#
### ls
# : 引数なしの場合、現在のディレクトリーの状態を返す
# : 引数ありの場合、そのディレクトリーの状態を返す
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
# -m 情報をカンマ区切りで表示する(未実装)
#
### +α
# -d ディレクトリ自体の情報を表示する
# -x 縦方向じゃなくて横方向に並べる
# -Q 情報をダブルクウォートで囲んで表示する
# --ignore=PATTERN PATTERNに一致する情報以外の情報を表示する
# etc.
#
### 追加要素
# -lSなどのオプションに対応できるようにする
#
###

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
	def initialize(entries, options)
		@entries = entries
		@options = options
	end

	def processing
		l_option if @options.include?('-l')
		h_option if @options.include?('-h')
		i_option if @options.include?('-i')
		@entries
	end

	private 

	# permission以外実装
	def l_option
		@entries.each do |entry|
			stat = File::Stat.new(entry[:name])
			entry[:file_type] = 'f' if stat.file?
			entry[:file_type] = 'd' if stat.directory?
			#entry[:permission] = nil
			entry[:num_hardlink] = stat.nlink
			entry[:owner_name] = stat.uid
			entry[:group_name] = stat.gid
			entry[:byte_size] = stat.size
			entry[:time_stamp] = stat.mtime
		end
	end

	def h_option
		@entries.each do |entry|
			if entry[:byte_size].nil?
				entry[:byte_size] = File::Stat.new(entry[:name]).size 
			end
			if entry[:byte_size] > 10**6
				entry[:byte_size] = "#{(entry[:byte_size] / 1000000).to_f.round(2)}G"
			elsif entry[:byte_size] > 10**3
				entry[:byte_size] = "#{(entry[:byte_size] / 1000).to_f.round(2)}k"
			end	
		end
	end

	def i_option
		@entries.each do |entry| 
			entry[:num_node] = File::Stat.new(entry[:name]).ino
		end
	end
end

class SortOption
	def initialize(entries, options)
		@entries = entries
		@options = options
	end

	def sort
		@entries = large_s_option if @options.include?('-S')
		@entries = t_option if @options.include?('-t')
		@entries = r_option if @options.include?('-r')
		@entries
	end

	private 

	def large_s_option
		@entries.each do |entry|
			stat = File::Stat.new(entry[:name])
			entry[:byte_size] = stat.size
		end
		@entries.sort{|a, b| b[:byte_size] <=> a[:byte_size]}
	end

	def t_option
		@entries.each do |entry|
			stat = File::Stat.new(entry[:name])
			entry[:time_stamp] = stat.mtime
		end
		@entries.sort{|a, b| b[:time_stamp] <=> a[:time_stamp]}
	end

	def r_option
		@entries.reverse
	end
end

class MakeOutput
	def initialize(entries, options)
		@entries = entries
		@options = options
	end

	def make_output
		@entries.each do |entry|
			outputs = []
			if @options.include?('-i')
				outputs << entry[:num_node]
			end
			if @options.include?('-l')
				outputs << entry[:file_type]
				#outputs << entry[:permission]
				outputs << entry[:num_hardlink]
				outputs << entry[:owner_name]
				outputs << entry[:group_name]
				outputs << entry[:byte_size].to_s.rjust(6, ' ')
				outputs << entry[:time_stamp]
			end
			stat = File::Stat.new(entry[:name])
			if stat.directory?
				outputs << "\e[42m#{entry[:name]}\e[0m"
			else
				outputs << entry[:name]
			end
			entry[:output] = outputs.join(' ')
		end
		@entries
	end
end

class OutputOption
	def initialize(entries, options)
		@entries = entries
		@options = options
	end

	def output
		if @options.include?('-1') || @options.include?('-l')
			one_option
		else
			@entries.map{|entry| entry[:output]}.join(' ')
		end
	end

	private 

	def one_option
		entries = @entries.map{|entry|
			"#{entry[:output]}\n"
		}
		entries.join('')
	end
end

class TempleteLS
	def initialize(entries, options)
		@entries = entries
		@options = options
	end

	def execute_ls
		@entries = FilterOption.new(@entries,@options).filter
		@entries = SortOption.new(@entries,@options).sort
		@entries = FilterOption.new(@entries,@options).filter
		@entries = ProcessingOption.new(@entries,@options).processing
		@entries = MakeOutput.new(@entries,@options).make_output
		@entries = OutputOption.new(@entries,@options).output
		@entries
	end
end

implemented_options = ['-a', '-l', '-1', '-r', '-t', '-S', '-h', '-i']

# lsで表示するディレクトリ target
target = Dir.pwd
ARGV.each do |f|
	target = f if f[0] != '-'
end

# 与えられたオプション options
options = ARGV.select{|e| e[0] == '-'}
options.each do |option|
	if !implemented_options.include?(option)
		puts("\e[36m#{option} is not available\e[0m")
		exit
	end
end

# 表示するファイルまたはディレクトリの集合 entries
begin
	entries = Dir::entries(target).map{|entry| {name: entry}} 
rescue => error
	puts("\e[36mSome options are not needed\e[0m")
	exit
end

puts TempleteLS.new(entries,options).execute_ls