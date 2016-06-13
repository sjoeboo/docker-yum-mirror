FROM centos:7

RUN yum -y install ruby rubygems ruby-devel rsync createrepo && yum -y update && yum clean all
RUN gem install bundler

COPY example_config.yaml /config.yaml
COPY yum_mirror.rb /yum_mirror.rb
COPY Gemfile /Gemfile

RUN cd / && bundle install

CMD /yum_mirror.rb
