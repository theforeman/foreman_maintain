class Features::DeleteArticles < ForemanMaintain::Feature
  metadata do
    label :delete_articles

    confine do
      true
    end
  end

  def one_year_old
    say 'Deleted tasks in planning state'
  end

  def with_zero_comments
    say 'Deleted tasks 30 days old'
  end
end
