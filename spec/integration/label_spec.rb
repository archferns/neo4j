require 'spec_helper'


#tests = Proc.new do
describe "Labels" do

  before(:all) do
    @prev_wrapped_classes = Neo4j::ActiveNode::Labels._wrapped_classes
    Neo4j::ActiveNode::Labels._wrapped_classes.clear

    class TestClass
      include Neo4j::ActiveNode
    end

    Neo4j::Label.create(:IndexedTestClass).drop_index(:name)

    class IndexedTestClass
      include Neo4j::ActiveNode
      property :name
      index :name # will index using the IndexedTestClass label
    end

    module SomeLabelMixin
      def self.mapped_label_name
        :some_label
      end

      def self.neo4j_session
        Neo4j::Session.current
      end

      extend Neo4j::ActiveNode::Labels::ClassMethods
    end

    class SomeLabelClass
      include Neo4j::ActiveNode
      include SomeLabelMixin
    end
  end


  after(:all) do
    Neo4j::ActiveNode::Labels._wrapped_classes.concat(@prev_wrapped_classes)
    Object.send(:remove_const, :IndexedTestClass)
    Object.send(:remove_const, :TestClass)
  end


  describe 'create' do
    it 'automatically sets a label' do
      p = TestClass.create
      p.labels.to_a.should == [:TestClass]
    end

    it "sets label for mixin classes" do
      p = SomeLabelClass.create
      p.labels.to_a.should =~ [:SomeLabelClass, :some_label]
    end
  end

  describe 'all' do
    it "finds it without an index" do
      p = TestClass.create
      TestClass.all.to_a.should include(p)
    end

    describe 'when indexed' do
      it 'can find it without using the index' do
        andreas = IndexedTestClass.create(name: 'andreas')
        result = IndexedTestClass.all
        result.should include(andreas)
      end

      it 'does not find it if it has been deleted' do
        jimmy = IndexedTestClass.create(name: 'jimmy')
        result = IndexedTestClass.all
        result.should include(jimmy)
        jimmy.destroy
        IndexedTestClass.all.should_not include(jimmy)
      end
    end
  end

  describe 'find' do
    it "finds it without an index" do
      p = TestClass.create
      TestClass.all.to_a.should include(p)
    end

    describe 'when indexed' do
      it 'can find it using the index' do
        IndexedTestClass.destroy_all
        kalle = IndexedTestClass.create(name: 'kalle')
        IndexedTestClass.find(name: 'kalle').should == kalle
      end

      it 'does not find it if deleted' do
        IndexedTestClass.destroy_all
        kalle2 = IndexedTestClass.create(name: 'kalle2')
        result = IndexedTestClass.find(name: 'kalle2')
        result.should == kalle2
        kalle2.destroy
        IndexedTestClass.all(name: 'kalle2').should_not include(kalle2)
      end
    end

    describe 'when finding using a Module' do

      it 'finds it' do
        thing = SomeLabelClass.create
        SomeLabelMixin.all.should include(thing)
      end
    end
  end


end

#share_examples_for 'Neo4j::ActiveNode with Mixin Index'do
#  before(:all) do
#    Neo4j::ActiveNode::Labels._wrapped_classes = []
#    Neo4j::ActiveNode::Labels._wrapped_labels = nil
#
#    Neo4j::Label.create(:BarIndexedLabel).drop_index(:baaz)
#    sleep(1) # to make it possible to search using this module (?)
#
#    module BarIndexedLabel
#      extend Neo4j::ActiveNode::Labels::ClassMethods # to make it possible to search using this module (?)
#      begin
#        index :baaz
#      rescue => e
#        puts "WARNING: sometimes neo4j has a problem with removing and adding indexes in tests #{e}" # TODO
#      end
#    end
#
#    class TestClassWithBar
#      include Neo4j::ActiveNode
#      include BarIndexedLabel
#    end
#  end
#
#
#  it "can be found using the Mixin Module" do
#    hej = TestClassWithBar.create(:baaz => 'hej')
#    BarIndexedLabel.find(:baaz, 'hej').should include(hej)
#    TestClassWithBar.find(:baaz, 'hej').should include(hej)
#    BarIndexedLabel.find(:baaz, 'hej2').should_not include(hej)
#    TestClassWithBar.find(:baaz, 'hej2').should_not include(hej)
#  end
#end

#describe 'Neo4j::ActiveNode, server', api: :server do
#  it_behaves_like 'Neo4j::ActiveNode'
#  it_behaves_like "Neo4j::ActiveNode with Mixin Index"
#end
#
#describe 'Neo4j::ActiveNode, embedded', api: :embedded do
#  it_behaves_like 'Neo4j::ActiveNode'
#  it_behaves_like "Neo4j::ActiveNode with Mixin Index"
#end
