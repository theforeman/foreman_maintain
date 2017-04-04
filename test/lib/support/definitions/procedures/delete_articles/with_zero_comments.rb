module Procedures::DeleteArticles
  class WithZeroComments < ForemanMaintain::Procedure
    metadata do
      for_feature(:delete_articles)
      description 'Delete all articles with zero comments'
    end

    def run
      feature(:delete_articles).with_zero_comments
    end

    def next_steps
      [procedure(:non_existing_procedure)] if fail?
    end
  end
end
