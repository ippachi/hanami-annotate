require 'dry/inflector'

module Hanami
  module Annotate
    module CLI
      class Generate < Hanami::CLI::Command
        def call(*)
          postgres
          @tables.each do |table|
            table_info = \
              `ruby -e "print %q{\\d #{table}}" | bundle exec hanami db console`

            comment = commentize(table_info)

            files = \
              Dir[Hanami.root.join('lib', '*', '{entities,repositories}', '*')]
              .grep(Regexp.new(Dry::Inflector.new.singularize(table)))

            adds_comments(files, comment)
          end
        end

        private

        def postgres
          output = `ruby -e "print '\\dt'" | bundle exec hanami db console`
          lines = output.each_line.grep(/\A.*public(?!.*schema_migrations)/)
          @tables = lines.map do |line|
            line.split('|')[1].strip
          end
        end

        def adds_comments(files, comment)
          remove_head_comment(files)
          files.each do |file|
            content = ''
            File.open(file) { |f| content += f.read }
            File.open(file, 'w') { |f| f.puts(comment + content) }
          end
        end

        def commentize(str)
          str.each_line.map do |line|
            line.insert(0, '#')
          end.join
        end

        def remove_head_comment(files)
          files.each do |file|
            index = 0
            comment_removed_content = ''
            File.open(file) do |f|
              raw_content = f.read

              lines = raw_content.each_line.to_a
              index = lines.index do |line|
                line.strip[0] != '#'
              end

              comment_removed_content = lines[index..-1].join
            end

            File.open(file, 'w') { |f| f.puts(comment_removed_content) }
          end
        end
      end
    end
  end
end

Hanami::CLI.register 'annotate', Hanami::Annotate::CLI::Generate
