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

class Journal < ActiveRecord::Base
  has_many :articles
  
  validates_presence_of :issn_print
  validates_uniqueness_of :issn_print
  validates_presence_of :issn_electronic
  validates_uniqueness_of :issn_electronic
  
  def issn
    issn_print[0..3] + "-" + issn_print[4..7]
  end
  
  def articles_count
    self.articles.count
  end
  
  def citations_count(source, options={})
    citations = []
    self.articles.each do |article|
      citations << article.retrievals.sum(:citations_count, :conditions => ["retrievals.source_id = ?", source])
      citations << article.retrievals.sum(:other_citations_count, :conditions => ["retrievals.source_id = ?", source])
    end
    citations = citations.sum
  end

end