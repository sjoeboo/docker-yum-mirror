FROM centos:7

RUN yum -y install wget zlib zlib-devel openssl-devel rsync createrepo && yum groupinstall -y "Development Tools"  && yum -y update && yum clean all
RUN cd /usr/src && wget https://cache.ruby-lang.org/pub/ruby/2.5/ruby-2.5.1.tar.gz --no-check-certificate && tar -xzf ruby-2.5.1.tar.gz && cd ruby-2.5.1 && ./configure && make  && make install
RUN gem update --system ; gem update; gem install bundler

COPY example_config.yaml /config.yaml
COPY yum_mirror.rb /yum_mirror.rb
COPY Gemfile /Gemfile

RUN cd / && bundle install

CMD /yum_mirror.rb
