require 'rails_helper'

RSpec.shared_examples "publishable" do
  let(:factory) { described_class.to_s.underscore.to_sym }
  
  let(:publishable) { create(factory) }
  
  it { should respond_to :published, :published?, :publish, :unpublish }
  
  it "can be published or unpublished" do
    publishable.publish
    expect(publishable.published?).to be true
    expect(publishable.published).to be true
    
    publishable.unpublish
    expect(publishable.published?).to be false
    expect(publishable.published).to be false
  end
  
  it "provides scopes for published and unpublished records" do
    init_pub_count = described_class.published.count
    init_unpub_count = described_class.unpublished.count
    
    new_pub_count = rand(1..3)
    new_unpub_count = rand(1..3)
    
    new_pub_count.times { create(factory, published: true) }
    new_unpub_count.times { create(factory, published: false) }
    
    pub_count = init_pub_count + new_pub_count
    unpub_count = init_unpub_count + new_unpub_count
    
    expect(described_class.all.count).to eq(pub_count + unpub_count)
    expect(described_class.published.count).to eq(pub_count)
    expect(described_class.unpublished.count).to eq(unpub_count)
  end
  
  it "allows for mass publishing and unpublishing" do
    rand(1..3).times { create(factory, published: true) }
    rand(1..3).times { create(factory, published: false) }
    count = described_class.all.count
    
    expect(described_class.published.count).to be > 0
    expect(described_class.unpublished.count).to be > 0
    
    described_class.publish_all
    
    expect(described_class.published.count).to eq(count)
    expect(described_class.unpublished.count).to eq(0)
    
    described_class.unpublish_all
    
    expect(described_class.published.count).to eq(0)
    expect(described_class.unpublished.count).to eq(count)
  end
  
end
