module Procedures::DeleteArticles
  class OneYearOld < ForemanMaintain::Procedure
    metadata do
      for_feature(:delete_articles)
      tags :release
      description 'Delete all articles created 1 year ago'
    end

    def run
      feature(:task_articles).one_year_old
    end

    def next_steps
      [procedure(Procedures::DeleteArticles::WithZeroComments)]
    end
  end
end
