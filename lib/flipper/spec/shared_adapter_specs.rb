# Requires the following methods:
# * subject - The instance of the adapter
shared_examples_for 'a flipper adapter' do
  let(:actor_class) { Struct.new(:flipper_id) }

  let(:flipper) { Flipper.new(subject) }
  let(:feature) { flipper[:stats] }

  let(:boolean_gate) { feature.gate(:boolean) }
  let(:group_gate)   { feature.gate(:group) }
  let(:actor_gate)   { feature.gate(:actor) }
  let(:actors_gate)  { feature.gate(:percentage_of_actors) }
  let(:random_gate)  { feature.gate(:percentage_of_random) }

  before do
    Flipper.register(:admins) { |actor|
      actor.respond_to?(:admin?) && actor.admin?
    }

    Flipper.register(:early_access) { |actor|
      actor.respond_to?(:early_access?) && actor.early_access?
    }
  end

  after do
    Flipper.unregister_groups
  end

  it "returns correct default values for the gates if none are enabled" do
    subject.get(feature).should eq({
      boolean_gate => nil,
      group_gate   => Set.new,
      actor_gate   => Set.new,
      actors_gate  => nil,
      random_gate  => nil,
    })
  end

  it "can enable get value for boolean gate" do
    subject.enable feature, boolean_gate, flipper.boolean

    result = subject.get(feature)
    result[boolean_gate].should eq('true')

    subject.disable feature, boolean_gate, flipper.boolean(false)

    result = subject.get(feature)
    result[boolean_gate].should be_nil
  end

  it "can fully disable all enabled things with boolean gate disable" do
    actor_22 = actor_class.new('22')
    subject.enable feature, boolean_gate, flipper.boolean
    subject.enable feature, group_gate, flipper.group(:admins)
    subject.enable feature, actor_gate, flipper.actor(actor_22)
    subject.enable feature, actors_gate, flipper.actors(25)
    subject.enable feature, random_gate, flipper.random(45)

    subject.disable feature, boolean_gate, flipper.boolean

    subject.get(feature).should eq({
      boolean_gate => nil,
      group_gate   => Set.new,
      actor_gate   => Set.new,
      actors_gate  => nil,
      random_gate  => nil,
    })
  end

  it "can enable, disable and get value for group gate" do
    subject.enable feature, group_gate, flipper.group(:admins)
    subject.enable feature, group_gate, flipper.group(:early_access)

    result = subject.get(feature)
    result[group_gate].should eq(Set['admins', 'early_access'])

    subject.disable feature, group_gate, flipper.group(:early_access)
    result = subject.get(feature)
    result[group_gate].should eq(Set['admins'])

    subject.disable feature, group_gate, flipper.group(:admins)
    result = subject.get(feature)
    result[group_gate].should eq(Set.new)
  end

  it "can enable, disable and get value for actor gate" do
    actor_22 = actor_class.new('22')
    actor_asdf = actor_class.new('asdf')

    subject.enable feature, actor_gate, flipper.actor(actor_22)
    subject.enable feature, actor_gate, flipper.actor(actor_asdf)

    result = subject.get(feature)
    result[actor_gate].should eq(Set['22', 'asdf'])

    subject.disable feature, actor_gate, flipper.actor(actor_22)
    result = subject.get(feature)
    result[actor_gate].should eq(Set['asdf'])

    subject.disable feature, actor_gate, flipper.actor(actor_asdf)
    result = subject.get(feature)
    result[actor_gate].should eq(Set.new)
  end

  it "can enable, disable and get value for percentage of actors gate" do
    subject.enable feature, actors_gate, flipper.actors(15)
    result = subject.get(feature)
    result[actors_gate].should eq('15')

    subject.disable feature, actors_gate, flipper.actors(0)
    result = subject.get(feature)
    result[actors_gate].should eq('0')
  end

  it "can enable, disable and get value for percentage of random gate" do
    subject.enable feature, random_gate, flipper.random(10)
    result = subject.get(feature)
    result[random_gate].should eq('10')

    subject.disable feature, random_gate, flipper.random(0)
    result = subject.get(feature)
    result[random_gate].should eq('0')
  end

  it "converts boolean value to a string" do
    subject.enable feature, boolean_gate, flipper.boolean
    result = subject.get(feature)
    result[boolean_gate].should eq('true')
  end

  it "converts the actor value to a string" do
    subject.enable feature, actor_gate, flipper.actor(actor_class.new(22))
    result = subject.get(feature)
    result[actor_gate].should eq(Set['22'])
  end

  it "converts group value to a string" do
    subject.enable feature, group_gate, flipper.group(:admins)
    result = subject.get(feature)
    result[group_gate].should eq(Set['admins'])
  end

  it "converts percentage of random integer value to a string" do
    subject.enable feature, random_gate, flipper.random(10)
    result = subject.get(feature)
    result[random_gate].should eq('10')
  end

  it "converts percentage of actors integer value to a string" do
    subject.enable feature, actors_gate, flipper.actors(10)
    result = subject.get(feature)
    result[actors_gate].should eq('10')
  end
end
