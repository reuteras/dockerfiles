FROM python:3.13-bookworm
LABEL maintainer="Coding <code@ongoing.today>"
RUN apt-get -y update && \
    apt-get -y dist-upgrade && \
    apt-get -y install --no-install-recommends cmake \
        git && \
    python3 -m pip install -U pip &&\
    python3 -m pip install -U \
        altair \
        deepeval \
        faiss-cpu \
        jq \
        langchain-community \
        langchain-core \
        langchain-openai \
        marimo[sql] \
        pandas \
        rank_bm25 &&\
    apt-get -y remove cmake git && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /data
ENTRYPOINT ["marimo", "edit", "--host", "*"]
EXPOSE  2718
