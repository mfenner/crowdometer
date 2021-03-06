# $HeadURL$
# $Id$
#
# Copyright (c) 2009-2010 by Public Library of Science, a non-profit corporation
# http://www.plos.org/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'doi'
require 'log4j_style_logger'

namespace :db do
  RAILS_DEFAULT_LOGGER = ActiveSupport::BufferedLogger.new "#{Rails.root.to_s}/log/#{Rails.env}_db_update_rake.log"
  
  task :update => :"db:update:stale"
  namespace :update do
    desc "Update stale articles"
    task :stale => :environment do
      puts "Start: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
      limit = (ENV["LIMIT"] || 0).to_i
      articles = if ENV["DOI"]
        doi = ENV["DOI"]
        ENV["LAZY"] ||= "0"
        article = Article.find_by_doi(doi) or abort("Article not found: #{doi}")
        [article]
      elsif ENV["LAZY"] == "0"
        Article.limit(limit)
      else
        Article.stale_and_published.limit(limit)
      end
      
      puts "Found #{articles.size} stale articles."

      Retriever.update_articles(articles)
      
      puts "Done: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
    end

    desc "Update all articles"
    task :all => :environment do
      ENV["LAZY"] = "0"
      limit = (ENV["LIMIT"] || 0).to_i
      articles = Article.limit(limit)
      Retriever.update_articles(articles)
    end

    desc "Update cited articles"
    task :cited => :environment do
      limit = (ENV["LIMIT"] || 0).to_i
      articles = Article.cited.limit(limit)
      Retriever.update_articles(articles, "cited")
    end

    desc "Update one specified article"
    task :one => :environment do
      short_doi = ENV["shortdoi"] or abort("shortDOI not specified (eg, 'shortdoi=foo')")
      article = Article.find_by_short_doi(short_doi) or abort("Article not found: #{short_doi}")
      ENV["LAZY"] ||= "0"
      Retriever.update_articles([article])
    end
    
    desc "Update all authors"
    task :authors => :environment do
      ENV["LAZY"] = "0"
      limit = (ENV["LIMIT"] || 0).to_i
      authors = Author.limit(limit)
      Retriever.update_authors(authors)
    end
    
    desc "Update one specified author"
    task :one_author => :environment do
      username = ENV["username"] or abort("Username not specified (eg, 'username=mfenner')")
      author = Author.find_by_username(username) or abort("Author not found: #{twitter}")
      ENV["LAZY"] ||= "0"
      Retriever.update_authors([author])
    end
    
    desc "Update all groups"
    task :groups => :environment do
      ENV["LAZY"] = "0"
      limit = (ENV["LIMIT"] || 0).to_i
      groups = Group.limit(limit)
      Retriever.update_groups(groups)
    end
    
    desc "Update one specified group"
    task :one_group => :environment do
      mendeley = ENV["mendeley"] or abort("Mendeley id for Group not specified (eg, 'mendeley=586171')")
      group = Group.find_by_mendeley(mendeley) or abort("Group not found: #{mendeley}")
      ENV["LAZY"] ||= "0"
      Retriever.update_groups([group])
    end

    desc "Count stale articles"
    task :count => :environment do
      article_count = Article.stale_and_published.count
      puts "#{article_count} stale articles found"
    end

    desc "Reset articles so individual sources' dates will be reconsidered"
    task :reset => :environment do
      Article.update_all("retrieved_at = '1970-01-01 00:00:00'")
      Retrieval.update_all("retrieved_at = '1970-01-01 00:00:00'")
    end

    desc "Reset all retrievals and citations"
    task :reset_all => :environment do
      Retrieval.delete_all
      Citation.delete_all
      History.delete_all
      Article.update_all("retrieved_at = '1970-01-01 00:00:00'")
    end

    desc "Reenable all disabled sources"
    task :reenable => :environment do
      # TODO: we should set disable_delay to Source.new.disable_delay, like we do in source.rb, instead of hard-coding the 10 here.
      Source.update_all("disable_until = NULL")
      Source.update_all("disable_delay = 10")
    end

    desc "Scan database for duplicate citations"
    task :dup_check => :environment do
      Retrieval.all.each do |retrieval|
        dups = []
        citations_by_uri = retrieval.citations.inject({}) do |h, citation|
          dups << citation if (h[citation.uri] ||= citation) != citation
          h
        end
        unless dups.empty?
          dups.each do |citation|
            puts "#{retrieval.article.doi} from #{retrieval.source.name} includes extra #{citation.uri}: #{citation.id}"
            if ENV['CLEANUP']
              puts "deleting citation #{citation.id}"
              retrieval.citations.delete(citation)
            end
          end
          if ENV['CLEANUP']
            new_count = retrieval.citations.size
            retrieval.histories.each do |h|
              if h.citations_count > new_count
                puts "updating history #{h.id}"
                h.citations_count = new_count
                h.save!
              end
            end
          end
        end
      end
    end
  end
end