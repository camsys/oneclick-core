require 'rails_helper'

RSpec.shared_examples "archivable" do
  let(:factory) { described_class.to_s.underscore.to_sym }
  
  let(:archivable) { create(factory) }
  
  it { should respond_to :archived, :archived?, :archive, :restore }
  
  it "can be archived or restored" do
    archivable.archive
    expect(archivable.archived?).to be true
    expect(archivable.archived).to be true
    
    archivable.restore
    expect(archivable.archived?).to be false
    expect(archivable.archived).to be false
  end
  
  it "excludes archived records from the default scope" do
    count = described_class.all.count
    archivable
    expect(described_class.all.count).to eq(count + 1)
    archivable.archive
    expect(described_class.all.count).to eq(count)
    archivable.restore
    expect(described_class.all.count).to eq(count + 1)
  end
  
  it "provides scope for viewing archived records" do
    count = described_class.archived.count
    archivable
    expect(described_class.archived.count).to eq(count)
    archivable.archive
    expect(described_class.archived.count).to eq(count + 1)
    archivable.restore
    expect(described_class.archived.count).to eq(count)    
  end
  
  it "provides scope for viewing all records, archived and non" do
    count = described_class.all.include_archived.count
    archivable
    expect(described_class.all.include_archived.count).to eq(count + 1)
    archivable.archive
    expect(described_class.all.include_archived.count).to eq(count + 1)
    archivable.restore
    expect(described_class.all.include_archived.count).to eq(count + 1)
  end
  
end
