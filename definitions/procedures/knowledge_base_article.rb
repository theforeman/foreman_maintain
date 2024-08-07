class Procedures::KnowledgeBaseArticle < ForemanMaintain::Procedure
  metadata do
    description 'Show knowledge base article for troubleshooting'

    confine do
      feature(:instance).downstream
    end
    param :doc,
      'Document name required to select a correct article',
      :required => true
    advanced_run false
  end

  def run
    ask(<<~MESSAGE)
      Go to #{kcs_documents[@doc]}
      please follow steps from above article to resolve this issue
      press ENTER once done.
    MESSAGE
  end

  private

  def kcs_documents
    {
      'fix_cpdb_validate_failure' => 'https://access.redhat.com/solutions/3362821',
      'fix_db_migrate_failure_on_duplicate_roles' => 'https://access.redhat.com/solutions/3998941',
      'many_fact_values' => 'https://access.redhat.com/solutions/4163891',
    }
  end
end
