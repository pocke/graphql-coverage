RSpec.shared_context :mktmpdir do
  let(:tmpdir) { Pathname(Dir.mktmpdir('graphql-coverage-test')) }

  after do
    FileUtils.remove_entry(tmpdir)
  end
end
