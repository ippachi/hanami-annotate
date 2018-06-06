require 'dry/inflector'

module Hanami
  module Annotate
    module CLI
      # Generate annotation for Hanami entities and repositories
      #
      # usage:
      #   $ bundle exec hanami annotate
      #
      # @todo add support for mysql and sqlite3 etc..
      #
      class Generate < Hanami::CLI::Command
        def call(*)
          postgres
          @table_names.each do |table_name|
            table_info = \
              `ruby -e "print %q{\\d #{table}}" | bundle exec hanami db console`

            comment = commentize(table_info)

            files = entity_and_repository_paths(table_name)
            remove_head_comments(files)
            adds_comments(files, comment)
          end
        end

        private

        def postgres
          output = `ruby -e "print '\\dt'" | bundle exec hanami db console`
          lines = output.each_line.grep(/\A.*public(?!.*schema_migrations)/)

          # tables is users, admins, books, etc
          @table_names = lines.map do |line|
            line.split('|')[1].strip
          end
        end

        def entity_and_repository_paths(table_name)
          Dir[Hanami.root.join('lib', '*', '{entities,repositories}', '*')]
            .grep(Regexp.new(Dry::Inflector.new.singularize(table_name)))
        end

        def adds_comments(files, comment)
          files.each do |file|
            content = ''
            File.open(file) { |f| content += f.read }
            File.open(file, 'w') { |f| f.puts(comment + content) }
          end
        end

        def commentize(str)
          str.each_line.map do |line|
            line.insert(0, '# ')
          end.join
        end

        def remove_head_comments(files)
          files.each do |file|
            comment_removed_content = ''
            File.open(file) do |f|
              raw_content = f.read

              lines = raw_content.each_line.to_a
              index = non_comment_line_number(lines)
              comment_removed_content = lines[index..-1].join
            end

            File.open(file, 'w') { |f| f.puts(comment_removed_content) }
          end
        end

        def non_comment_line_number(lines)
          lines.index do |line|
            line.strip[0] != '#'
          end
        end
      end
    end
  end
end

Hanami::CLI.register 'annotate', Hanami::Annotate::CLI::Generate
